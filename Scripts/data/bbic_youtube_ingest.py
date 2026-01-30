#!/usr/bin/env python3
"""
BBIC YouTube Ingest:
- Pull recent videos for configured channels via uploads playlist (low quota)
- Optionally pull keyword searches (conservative; search.list=100 units)
- Optionally fetch transcripts (when available)
- Persist raw as JSONL and emit a curated daily trends file
"""
import os, json, time, dataclasses, datetime as dt
from typing import List, Dict, Any
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()
import yaml
from tenacity import retry, wait_exponential, stop_after_attempt
from googleapiclient.discovery import build
import requests
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CONFIG = os.path.join(ROOT, "config", "bbic.youtube.yaml")

@dataclasses.dataclass
class VideoDoc:
    video_id: str
    title: str
    channel_id: str
    channel_title: str
    published_at: str
    description: str
    tags: List[str]
    view_count: int | None
    like_count: int | None
    comment_count: int | None
    transcript: str | None
    url: str

def load_conf() -> Dict[str, Any]:
    with open(CONFIG, "r") as f:
        return yaml.safe_load(f)

def ensure_dirs(paths: List[str]):
    for p in paths:
        os.makedirs(p, exist_ok=True)

def now_utc_iso():
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

def load_state(path: str) -> Dict[str, Any]:
    if os.path.exists(path):
        with open(path, "r") as f:
            return json.load(f)
    return {"last_seen": {}}

def save_state(path: str, state: Dict[str, Any]):
    with open(path, "w") as f:
        json.dump(state, f, indent=2)

@retry(wait=wait_exponential(multiplier=1, min=2, max=30), stop=stop_after_attempt(5))
def youtube_client():
    key = os.environ.get("YT_API_KEY")
    if not key:
        raise RuntimeError("Missing YT_API_KEY env var")
    return build("youtube", "v3", developerKey=key)

def get_uploads_playlist_id(yt, channel_id: str) -> str:
    resp = yt.channels().list(part="contentDetails,snippet", id=channel_id).execute()
    items = resp.get("items", [])
    if not items:
        raise RuntimeError(f"Channel not found: {channel_id}")
    return items[0]["contentDetails"]["relatedPlaylists"]["uploads"]

def list_playlist_items(yt, playlist_id: str, max_results: int) -> List[Dict[str, Any]]:
    out = []
    page_token = None
    while len(out) < max_results:
        req = yt.playlistItems().list(
            part="snippet,contentDetails",
            playlistId=playlist_id,
            maxResults=min(50, max_results - len(out)),
            pageToken=page_token
        )
        resp = req.execute()
        out.extend(resp.get("items", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return out

def list_keyword_search(yt, query: str, max_results: int) -> List[Dict[str, Any]]:
    # Use sparingly; search.list costs 100 units per call.
    req = yt.search().list(
        part="snippet",
        q=query,
        type="video",
        order="date",
        maxResults=min(25, max_results)
    )
    return req.execute().get("items", [])

def fetch_video_stats(yt, ids: List[str]) -> Dict[str, Dict[str, Any]]:
    stats_map = {}
    for i in range(0, len(ids), 50):
        chunk = ids[i:i+50]
        resp = yt.videos().list(part="statistics,snippet", id=",".join(chunk)).execute()
        for it in resp.get("items", []):
            vid = it["id"]
            st = it.get("statistics", {})
            sn = it.get("snippet", {})
            stats_map[vid] = {
                "viewCount": int(st.get("viewCount", 0)) if st.get("viewCount") else None,
                "likeCount": int(st.get("likeCount", 0)) if st.get("likeCount") else None,
                "commentCount": int(st.get("commentCount", 0)) if st.get("commentCount") else None,
                "tags": sn.get("tags", []),
                "channelTitle": sn.get("channelTitle", "")
            }
    return stats_map

def fetch_transcript(video_id: str) -> str | None:
    try:
        tran = YouTubeTranscriptApi.get_transcript(video_id, languages=['en', 'es'])
        return " ".join([t.get("text","") for t in tran]).strip()
    except (TranscriptsDisabled, NoTranscriptFound):
        return None
    except Exception:
        return None

def to_videodoc(snippet: Dict[str, Any], stats: Dict[str, Any]) -> VideoDoc:
    vid = snippet["resourceId"]["videoId"] if "resourceId" in snippet else snippet["id"]["videoId"]
    url = f"https://www.youtube.com/watch?v={vid}"
    return VideoDoc(
        video_id=vid,
        title=snippet["title"],
        channel_id=snippet.get("channelId", ""),
        channel_title=stats.get("channelTitle") or snippet.get("channelTitle",""),
        published_at=snippet["publishedAt"],
        description=snippet.get("description", ""),
        tags=stats.get("tags", []),
        view_count=stats.get("viewCount"),
        like_count=stats.get("likeCount"),
        comment_count=stats.get("commentCount"),
        transcript=None,  # fill later if enabled
        url=url
    )

def write_jsonl(path: str, records: List[Dict[str, Any]]):
    with open(path, "a", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

def main():
    conf = load_conf()
    root = os.path.join(ROOT, conf["storage"]["root"])
    curated_dir = os.path.join(ROOT, conf["storage"]["curated_dir"])
    state_path = os.path.join(ROOT, conf["storage"]["state_file"])
    ensure_dirs([root, curated_dir, os.path.dirname(state_path)])

    state = load_state(state_path)
    yt = youtube_client()

    new_docs: List[VideoDoc] = []

    # 1) Channels via uploads playlist (cheap)
    for ch in conf["sources"].get("channels", []):
        ch_id = ch["id"]
        uploads = get_uploads_playlist_id(yt, ch_id)
        items = list_playlist_items(yt, uploads, conf["limits"]["per_channel_recent"])
        video_snippets = [it["snippet"] for it in items if it.get("snippet", {}).get("resourceId")]
        video_ids = [sn["resourceId"]["videoId"] for sn in video_snippets]
        stats = fetch_video_stats(yt, video_ids) if conf["features"]["fetch_stats"] else {}
        last_seen = state["last_seen"].get(ch_id)

        for sn in video_snippets:
            vid = sn["resourceId"]["videoId"]
            doc = to_videodoc(sn, stats.get(vid, {}))
            if last_seen and doc.published_at <= last_seen:
                continue
            if conf["features"]["fetch_transcripts"]:
                doc.transcript = fetch_transcript(doc.video_id)
            new_docs.append(doc)

        # bump state
        if video_snippets:
            newest = max(x["publishedAt"] for x in video_snippets)
            state["last_seen"][ch_id] = max(newest, last_seen) if last_seen else newest

    # 2) Keywords (use sparingly)
    kw_limit = conf["limits"]["per_keyword_results"]
    for q in conf["sources"].get("keywords", []):
        items = list_keyword_search(yt, q, kw_limit)
        video_snippets = [it["snippet"] for it in items if it["id"]["kind"] == "youtube#video"]
        video_ids = [it["id"]["videoId"] for it in items if it["id"]["kind"] == "youtube#video"]
        stats = fetch_video_stats(yt, video_ids) if conf["features"]["fetch_stats"] else {}
        for sn, vid in zip(video_snippets, video_ids):
            doc = to_videodoc({"id":{"videoId":vid}, **sn}, stats.get(vid, {}))
            if conf["features"]["fetch_transcripts"]:
                doc.transcript = fetch_transcript(doc.video_id)
            new_docs.append(doc)

    # 3) Persist raw JSONL
    if new_docs:
        day = dt.datetime.utcnow().strftime("%Y-%m-%d")
        raw_path = os.path.join(root, f"raw_{day}.jsonl")
        write_jsonl(raw_path, [dataclasses.asdict(d) for d in new_docs])

        # 4) Curate light "trends" file (top by views; fallback to recency)
        top = sorted(new_docs, key=lambda d: (d.view_count or 0, d.published_at), reverse=True)[:20]
        curated = {
            "generated_at": now_utc_iso(),
            "count": len(top),
            "items": [dataclasses.asdict(d) for d in top]
        }
        curated_path = os.path.join(curated_dir, f"trends_{day}.json")
        with open(curated_path, "w", encoding="utf-8") as f:
            json.dump(curated, f, ensure_ascii=False, indent=2)

        print(f"[bbic] Saved {len(new_docs)} videos; curated → {curated_path}")
    else:
        print("[bbic] No new videos found.")

    save_state(state_path, state)

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
import os, json, datetime as dt, yaml
import praw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CONF = os.path.join(ROOT, "config", "bbic.reddit.yaml")

def main():
    conf = yaml.safe_load(open(CONF))
    auth = conf["auth"]
    reddit = praw.Reddit(
        client_id=auth["client_id"],
        client_secret=auth["client_secret"],
        user_agent=auth["user_agent"],
    )
    store = os.path.join(ROOT, conf["storage"]["root"])
    os.makedirs(store, exist_ok=True)
    day = dt.datetime.utcnow().strftime("%Y-%m-%d")
    outp = os.path.join(store, f"reddit_{day}.jsonl")
    limit = conf["intake"]["limit_per_subreddit"]
    tfilter = conf["intake"]["time_filter"]

    with open(outp, "a", encoding="utf-8") as f:
        for sub in conf["intake"]["subreddits"]:
            for post in reddit.subreddit(sub).top(time_filter=tfilter, limit=limit):
                rec = {
                    "subreddit": sub,
                    "id": post.id,
                    "title": post.title,
                    "score": post.score,
                    "url": post.url,
                    "created_utc": post.created_utc,
                    "num_comments": post.num_comments
                }
                f.write(json.dumps(rec) + "\n")
    print(f"[bbic] Reddit saved → {outp}")

if __name__ == "__main__":
    main()
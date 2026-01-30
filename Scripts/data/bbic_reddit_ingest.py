#!/usr/bin/env python3
import os, json, datetime as dt, yaml
import praw
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CONF = os.path.join(ROOT, "config", "bbic.reddit.yaml")

def main():
    # Load and substitute environment variables in config
    conf_content = open(CONF).read()
    conf_content = os.path.expandvars(conf_content)
    conf = yaml.safe_load(conf_content)
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
        total_subs = len(conf["intake"]["subreddits"])
        for i, sub in enumerate(conf["intake"]["subreddits"], 1):
            print(f"[bbic] Processing {sub} ({i}/{total_subs})...")
            try:
                posts_processed = 0
                for post in reddit.subreddit(sub).top(time_filter=tfilter, limit=limit):
                    rec = {
                        "subreddit": sub,
                        "id": post.id,
                        "title": post.title,
                        "score": post.score,
                        "url": post.url,
                        "created_utc": post.created_utc,
                        "num_comments": post.num_comments,
                        "upvote_ratio": getattr(post, 'upvote_ratio', None),
                        "author": str(getattr(post, 'author', 'deleted'))
                    }
                    f.write(json.dumps(rec) + "\n")
                    posts_processed += 1
                print(f"[bbic] ✓ {sub}: {posts_processed} posts collected")
            except Exception as e:
                print(f"[bbic] ✗ {sub}: Error - {e}")
                continue
    print(f"[bbic] Reddit saved → {outp}")

if __name__ == "__main__":
    main()
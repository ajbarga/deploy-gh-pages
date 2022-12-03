from github import Github
from sys import argv


def get_args():
	g = Github(argv[1])
	r = g.get_repo(argv[2])
	pr = r.get_pull(int(argv[3]))
	merge = argv[4] == 'true'
	return r, pr, merge


def main(r, pr_main, merge):
	pr_list = [p for p in r.get_pulls(state='closed') if p.merged == True]
	pr_list.sort(key=lambda p: p.number, reverse=True)

	pr = pr_main
	merged_pr = pr_list[0]
	
	dt = [c for c in r.get_commits(since=r.get_commit(merged_pr.merge_commit_sha).commit.author.date)]
	dt.sort(key=lambda c: c.commit.author.date)
	commits = r.compare(base=dt[0].sha, head=dt[-1].sha).commits
	commit_list = []
	count = 0
	newline = '\n\n'
	for c in commits:
		message = '\n - '.join([f'{file.filename}: + {file.additions}, - {file.deletions}' for file in c.files])
		commit_list.append(f'{count}: {c.commit.message} @{c.commit.author.name} {c.html_url}\n - {message}')
		count += 1
	pr.edit(body=f"{pr.body}\n\n{newline.join(commit_list)}")
	pr.create_review(event="APPROVE")
	if merge:
		r.merge(base=pr.base.ref, head=pr.head.ref, commit_message=f"Merge branch {pr.head.ref} into {pr.base.ref}")


if __name__ == '__main__':
	repo, pr, merge = get_args()
	main(repo, pr, merge)

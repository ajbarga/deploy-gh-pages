from github import Github
from sys import argv


def get_args():
	g = Github(argv[1])
	return g.get_repo(argv[2])


def main(r):
	pr_list = [p for p in r.get_pulls(state='open')] + [p for p in r.get_pulls(state='closed') if p.merged == True]
	pr_list.sort(key=lambda p: p.number, reverse=True)
	pr = pr_list[0]
	merged_pr = [p for p in pr_list if p.state == 'closed'][0]
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
	if '#M' in pr.title:
		r.merge(base=pr.base.ref, head=pr.head.ref, commit_message=f"Merge branch {pr.head.ref} into {pr.base.ref}")


if __name__ == '__main__':
	repo = get_args()
	main(repo)

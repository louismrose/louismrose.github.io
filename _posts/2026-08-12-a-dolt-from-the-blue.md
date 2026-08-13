---
layout: post
title: A Dolt from the blue
tags:
  - Dolt
  - Git
---

I've been playing with [Dolt](https://www.dolthub.com/docs/introduction/what-is-dolt/) lately. It's a SQL database, but 
versioned like a Git repository.

I noticed that Dolt can use a Git repository as its backing store. This seems like a fascinating way to store versioned 
metadata alongside source code. I wondered whether Dolt's artefacts would be visible in the Git repository and interfere
with normal Git operations, but it seems they don't. So how does it work?

The meat of a Git repository is its [object database](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects). Files 
and directory trees can be added to the database, with Git assigning each object a unique identifier based on its 
contents. Commits are objects too, tying a tree of files to metadata and, usually, one or more parent commits.

When I configured Dolt to push to a Git remote, it was writing its own commit history into the remote's Git object 
database. I next wondered why those commits don't show up in typical `git` operations on the repo.

The answer, it seems, lies in [refs](https://git-scm.com/book/ms/v2/Git-Internals-Git-References). Git commit objects 
point to their parents, forming a graph of history. But there doesn't have to be just one connected graph: a single 
object database can contain several disconnected histories. `git` commands use refs to find interesting traversal 
points in those graphs, such as the latest commit on a branch.

These pieces explain how Dolt is able to smuggle versioned data into a Git repository. Its commits live in the same 
object database as the source history, but form a separate graph. Dolt then maintains its own `refs/dolt/data` ref 
pointing at the latest commit in that graph. Normal Git branches continue to point into the source-code graph, so most 
everyday Git operations never encounter the Dolt history.

(Understanding these Git internals better also gave me a new appreciation for `git reflog`. I've used it before to rescue 
a commit that I'd left stranded after an errant rebase. Now I understand why that works: the commit object hasn't 
immediately disappeared just because my branch no longer points to it. The reflog records previous positions of refs, 
giving me a way back into parts of the commit graph that I've otherwise left behind).

In the age of LLMs and coding agents, it's tempting to blow past all the little details while we're hurrying along; 
making software faster and faster. I still get a kick out of understanding how the pieces fit together. And now we have 
tutors with seemingly endless patience, ready to follow us down whatever rabbit holes we find.

What a time to be curious.
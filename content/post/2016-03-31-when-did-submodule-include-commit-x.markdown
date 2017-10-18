---
date: 2016-03-31T08:45:25Z
title: When did submodule include commit X
---

Cloud Foundry uses [git submodules][] in [cloudfoundry/cf-release][] to
track dependencies from other repositories such as
[cloudfoundry/gorouter][].

[git submodules]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
[cloudfoundry/cf-release]: https://github.com/cloudfoundry/cf-release
[cloudfoundry/gorouter]: https://github.com/cloudfoundry/gorouter

It's quite straightforward to find out what version of gorouter is included
in a given [version of cf-release][]:

[version of cf-release]: https://github.com/cloudfoundry/cf-release/releases

```sh
➜  cf-release git:(master) ✗ git ls-tree v230 -- src/github.com/cloudfoundry/gorouter
160000 commit 37445fabe4b3a79c5e22f6c1a4e9a950858490cb  src/github.com/cloudfoundry/gorouter
➜  cf-release git:(master) ✗ git ls-tree v231 -- src/github.com/cloudfoundry/gorouter
160000 commit 9a19ec5d3577799d07bab7d058d3614bfcf9ec4c  src/github.com/cloudfoundry/gorouter
➜  cf-release git:(master) ✗ git ls-tree v232 -- src/github.com/cloudfoundry/gorouter
160000 commit 15e5d4a2173a978f87c0903cdda1eea374afdfbf  src/github.com/cloudfoundry/gorouter
```

But how do you find out the opposite; what are the versions of cf-release
that include a specific commit from gorouter?

Not very easily, it seems. If it were a single repo then you could use `git
tag --contains`, but that doesn't work across submodules. I had a Google
around and couldn't find any suggestions. So based on some suggestions from
my colleagues [@thekeymon][] and [@timmow][] I hacked together something
that would brute force the information out:

[@thekeymon]: https://twitter.com/thekeymon
[@timmow]: https://twitter.com/timmow

```sh
#!/bin/bash
set -euo pipefail

path=$1
commit=$2

good_commits=$(git -C "${path}" rev-list "${commit}"^..HEAD)
if [ -z "${good_commits}" ]; then
  exit 1
fi

for parent_commit in $(git rev-list --reverse HEAD -- "${path}"); do
  sub_commit=$(git ls-tree -d "${parent_commit}" -- "${path}" | awk '{print $3}')
  if [ -z "${sub_commit}" ]; then
    continue
  fi
  if echo "${good_commits}" | grep -qw "${sub_commit}"; then
    echo "${parent_commit}"
    exit 0
  fi
done

exit 1
```

If you put the script in your `PATH` as `git-submodule-contains` then you
can use it as follows to find out which versions of cf-release included the
commit [cloudfoundry/gorouter@d5c6aea][]:

[cloudfoundry/gorouter@d5c6aea]: https://github.com/cloudfoundry/gorouter/commit/d5c6aeacce7648d4b929a20f55682404e87187de

```sh
➜  cf-release git:(master) git tag --contains \
> $(git submodule-contains src/github.com/cloudfoundry/gorouter d5c6aea)
v231
v232
v233
```

PS: I remain, as ever, not a fan of submodules.

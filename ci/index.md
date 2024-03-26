---
---

## Outline

- Start with designing some of the APIs, using types to test/communicate ideas
- Implementation following the 'scoping of CI system' section below
  I'd like to avoid platforms as much as possible in this section
- End with packaging the work up using a Roc platform

## Platforms in this chapter

The real system I hope to evolve this into will be a Roc platform for CI systems, and I think it could be a nice example of why platforms are a cool idea.
Roc platforms are not themselves written in Roc, so the work building the platform is not suitable material for this book.

I plan to use the basic-cli platform to get running code at the end of the chapter.
That will amount to "add a platform to turn Roc into something actually usable", which doesn't communicate why platforms are useful.
For that reason I think it makes sense to avoid focusing on platforms in this chapter.

## Scoping of the CI system created in the chapter

🔭 out of scope for this chapter
✂️ opportunities to cut scope further

- Create an API for writing CI jobs in Roc, consisting of multiple CI steps
  - Steps can define inputs and outputs
  - Steps can take outputs from other steps, introducing an order dependency
  - Steps can run system commands
    🔭 Designing Roc-wrappers for tools commonly used in CI (git/go/rspec/..)
  - ✂️ Steps run in an environment
    🔭 Defining environments in other ways than through a Dockerfile
  - 🔭 Caching
- Function that takes a step, it's inputs, and runs it
  - Capture data about each step
    - stdout and stderr
    - inputs and ouputs of step
    - start/end times of step
      🔭 capturing more fine-grained timings, such as of commands ran in steps
    - success or failure
    - 🔭 capturing test output in a structured format
- Implement functionality for scheduling and running jobs
    - Taking in requests to run jobs and queue them
      ✂️ Deduplicating requests to run the same job with the same inputs in the queue
    - Running a job, by running it's steps in dependency order
    - Design for allowing work to be distributed across a cluster of CI workers
      🔭 Implementation of clustering is out of scope
    - 🔭 support for pull-based jobs (i.e. Github events)
    - 🔭 running jobs in parallel
- ✂️ Some form of human interface for querying CI system progress
  For a real system I'd like this to be a web UI, for the chapter I wonder if a CLI is good enough, or even to punt on this entirely.

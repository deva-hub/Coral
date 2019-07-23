# Contributing

First off, thanks for taking the time to contribute! This guide will answer
some common questions about how this project works.

While this is an open source project, we welcome contributions from
everyone. Several regular outside contributors are also project maintainers.

## Making Changes

1. Fork this repository to your own account
2. Make your changes and verify that `mix test` passes
3. Commit your work and push to a new branch on your fork
4. Submit a [pull request](https://github.com/deva-hub/ELF/compare/)
5. Participate in the code review process by responding to feedback

Once there is agreement that the code is in good shape, one of the project's
maintainers will merge your contribution.

To increase the chances that your pull request will be accepted:

- Follow the style guide
- Write tests for your changes
- Write a good commit message

## Style

We use [`mix format`][mix_format]-based code formatting. The format will be enforced by
Gitlab CI, so please make sure your code is well formatted *before* you push
your branch so those checks will pass.

We also use [Credo][credo] for static analysis and code consistency. You can run it
locally via `mix credo`.

[credo]: https://github.com/rrrene/credo
[mix_format]: https://hexdocs.pm/mix/Mix.Tasks.Format.html

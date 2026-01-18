# Gary's Automated Dev Setup Script

## Installation

### Usage

Installs Homebrew, Ruby, Python, Node, and global npm packages

```bash
bin/setup
```

Note: If Homebrew is not already installed, it will prompt you for sudo access. This comes from the [Homebrew setup script](https://raw.githubusercontent.com/Homebrew/install/master/install.sh). See [https://brew.sh](https://brew.sh/) for more information.

## Development

### Contributing

To set up your local development environment for this repository, run:

```bash
./bin/bootstrap
```

This will install `bats-core` and configure git hooks to ensure tests pass and trailing whitespace is blocked.

### Semantic Commits

This project follows [Conventional Commits](https://www.conventionalcommits.org/). This allows us to automate versioning and changelogs. Please use the following prefixes for your commits:

- `fix:`: A bug fix (triggers a Patch release).
- `feat:`: A new feature (triggers a Minor release).
- `feat!:` or `fix!:`: A breaking change (triggers a Major release).
- `chore:`, `docs:`, `style:`, `refactor:`, `test:`: Changes that do not affect the production code (do not trigger a release).

### Release Procedures

We use [Release Please](https://github.com/google-github-actions/release-please-action) for automated releases.

1. Push your changes to `main` using Semantic Commits.
2. `release-please` will automatically create or update a **Release PR**.
3. This PR includes an updated `CHANGELOG.md` and bumps the `VERSION` file.
4. When you are ready to release, simply **merge the Release PR**.
5. GitHub Actions will then automatically create a GitHub Release and tag the code.

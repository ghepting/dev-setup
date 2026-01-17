# Testing dev-setup Safely

To ensure the scripts work correctly without affecting your host machine, you can use the following methods:

## 1. Debian Integration Testing (Recommended)

Use Docker to run the entire setup in a clean Debian environment:

```bash
# Build the test image
docker build -t dev-setup-debian -f test/Dockerfile.debian .

# Run the setup script in a container
# (Note: This will not have access to your actual 1Password)
docker run --rm -it -v $(pwd):/home/tester/dev-setup dev-setup-debian
```

## 2. Unit Testing (Logic Only)

Use `bats-core` to verify the logic of individual shell functions using mocks.

### Prerequisites

Install `bats-core`:

```bash
brew install bats-core
```

### Running Tests

Execute the tests from the root of the repository:

```bash
bats test/
```

This will run all `.bats` files in the `test/` directory, mocking system commands like `brew`, `apt-get`, and `uname` to ensure the logic follows the expected paths for each operating system.

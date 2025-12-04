# Contributing to Zabbix Proxy SQLite3 AV Edition

Thank you for your interest in contributing to the Zabbix Proxy SQLite3 AV Edition project! We welcome contributions from the community to help improve this tool for AV professionals.

## 🤝 How to Contribute

### Reporting Bugs

If you find a bug, please create a new issue in the [Issue Tracker](https://github.com/justprosound/zabbix-proxy-sqlite3-av-edition/issues) with the following information:

- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs **Actual behavior**
- **Logs** or screenshots if applicable
- **Environment details** (OS, Docker version, Zabbix version)

### Suggesting Enhancements

We love hearing about new ideas! If you have a suggestion for a new feature or improvement:

1. Check existing issues to see if it has already been proposed.
2. Open a new issue with the "enhancement" label.
3. Describe the feature and the problem it solves.

### Pull Requests

1. **Fork** the repository.
2. **Create a branch** for your feature or fix: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add some amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open a Pull Request** targeting the `main` branch.

## 🛠️ Development Workflow

### Local Development

To build the container locally for testing:

```bash
# Build the container
docker build -t zabbix-proxy-av:local .

# Run the container
docker run -d --name zabbix-proxy-test zabbix-proxy-av:local
```

### GitHub Actions Workflows

This project uses GitHub Actions for CI/CD. Here are the key workflows:

- **Main CI/CD Pipeline** (`main-ci.yml`): Runs on push to `main` and daily schedule. It detects Zabbix versions, builds containers, and publishes them.
- **Build Container** (`build-container.yml`): Reusable workflow that builds and scans the container.
- **Check Changes** (`check-changes.yml`): Determines if a rebuild is necessary based on commits and upstream changes.

### Release Process

Releases are automated via GitHub Actions:

1. **Upstream Updates**: When a new Zabbix version is detected, a release is automatically created.
2. **Local Changes**: If you modify the `Dockerfile` or scripts, the patch version is incremented (e.g., `7.0.13.1`).
3. **Manual Trigger**: You can manually trigger a build via the "Actions" tab in GitHub.

## 📝 Coding Standards

- **Shell Scripts**: Follow [ShellCheck](https://www.shellcheck.net/) guidelines.
- **Dockerfile**: Follow best practices for container image creation (minimize layers, clean up cache).
- **Documentation**: Keep `README.md` and other docs up to date with your changes.

## 📄 License

By contributing, you agree that your contributions will be licensed under the [GNU AGPLv3](LICENSE).

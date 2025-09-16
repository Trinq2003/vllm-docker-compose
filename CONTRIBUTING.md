# 🤝 Contributing to Deployment Repository

Thank you for your interest in contributing to the Deployment Repository! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Coding Standards](#-coding-standards)
- [Testing](#-testing)
- [Documentation](#-documentation)
- [Submitting Changes](#-submitting-changes)
- [Reporting Issues](#-reporting-issues)
- [Community](#-community)

## 📜 Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. By participating, you agree to:

- Be respectful and inclusive
- Focus on constructive feedback
- Accept responsibility for mistakes
- Show empathy towards other contributors
- Help create a positive community

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Python 3.12+** installed
- **Docker & Docker Compose** installed
- **NVIDIA GPU** with CUDA support (for GPU services)
- **Git** for version control
- **Hugging Face account** with API token

### Initial Setup

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/vllm-deployment.git
   cd vllm-deployment
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   make dev-install
   ```

4. **Set up pre-commit hooks**
   ```bash
   pre-commit install
   ```

5. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

6. **Verify setup**
   ```bash
   make test
   make lint
   ```

## 🔄 Development Workflow

### 1. Choose an Issue

- Check the [Issues](https://github.com/your-org/vllm-deployment/issues) page
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to indicate you're working on it

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

### 3. Make Changes

- Write clear, focused commits
- Test your changes thoroughly
- Update documentation as needed
- Follow the coding standards

### 4. Test Your Changes

```bash
# Run tests
make test

# Run linting
make lint

# Format code
make format

# Check health
make health-check
```

### 5. Submit a Pull Request

- Push your branch to GitHub
- Create a Pull Request with a clear description
- Reference any related issues
- Wait for review and address feedback

## 💻 Coding Standards

### Python Style

This project uses several tools to maintain code quality:

- **Black**: Code formatting (88 character line length)
- **isort**: Import sorting
- **Ruff**: Fast Python linter
- **MyPy**: Static type checking

```bash
# Format code
make format

# Run all checks
make lint
```

## 📚 Documentation

### Code Documentation

- All public functions and classes must have docstrings
- Update docstrings when changing function signatures
- Include examples in docstrings where helpful

### User Documentation

- Update README.md for new features
- Add examples for new functionality
- Update configuration documentation

### Building Documentation

```bash
# Build documentation
make docs

# Serve locally
make serve-docs
```

## 🔄 Submitting Changes

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

Examples:
```
feat(vllm): add support for Qwen3-30B model

fix(health): handle connection timeouts in health checks

docs(readme): update deployment instructions
```

### Pull Request Process

1. **Create a descriptive PR title**
   ```
   feat: Add support for model autoscaling
   ```

2. **Provide a detailed description**
   - What changes were made
   - Why the changes were needed
   - How to test the changes
   - Any breaking changes

3. **Reference issues**
   ```
   Closes #123
   Fixes #456
   ```

4. **Request review**
   - Tag appropriate reviewers
   - Ensure CI checks pass

5. **Address feedback**
   - Respond to review comments
   - Make requested changes
   - Update PR description if needed

## 🐛 Reporting Issues

### Bug Reports

When reporting bugs, please include:

- **Clear title** describing the issue
- **Steps to reproduce** the problem
- **Expected behavior**
- **Actual behavior**
- **Environment details** (OS, Python version, Docker version)
- **Logs** and error messages
- **Screenshots** if applicable

### Feature Requests

For feature requests, please include:

- **Clear description** of the proposed feature
- **Use case** and why it's needed
- **Proposed implementation** if you have ideas
- **Alternatives considered**

---

Thank you for contributing to the Deployment Service! Your contributions help make this project better for everyone. 🚀

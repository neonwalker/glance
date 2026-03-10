# Glance

[![Build](https://github.com/neonwalker/glance/actions/workflows/build.yml/badge.svg)](https://github.com/neonwalker/glance/actions/workflows/build.yml)

A lightweight macOS menu bar app for monitoring GitHub Actions CI/CD pipelines in real time.

![App Demo](assets/demo.gif)

## Features

- **Live status** - see passing, failing, running, and queued workflow runs at a glance
- **Multiple repos** - monitor as many repositories as you like from one place
- **Smart icon** - the menu bar icon reflects the worst state across all your pipelines
- **ETag caching** - conditional requests mean unchanged results don't count against your API rate limit
- **Rate limit display** - see remaining API calls and when the limit resets
- **Notifications** - get a macOS notification when a build finishes or fails
- **Configurable polling** - check every 15 seconds up to 5 minutes

## Requirements

- macOS 26.2 or later
- A GitHub [fine-grained personal access token](https://github.com/settings/tokens) with **Actions (read)** permission

## Setup

1. Download and run Glance
2. Click the menu bar icon and open **Settings**
3. Paste your GitHub token into the **Token** field
4. Switch to the **Repositories** tab and add repos in `owner/repo` format

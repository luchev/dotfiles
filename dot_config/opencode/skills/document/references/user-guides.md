# User Guides

Load when writing a tutorial or onboarding guide.


**Tutorial structure**:

```markdown
# Getting Started with [Feature]

## What You'll Learn

In this guide, you'll learn how to:
- Set up [feature]
- Perform basic operations
- Handle common scenarios
- Troubleshoot issues

## Prerequisites

- Node.js 18+
- Basic understanding of TypeScript
- Account on [service]

## Step 1: Installation

```bash
npm install package-name
```

Expected output:
```
+ package-name@1.2.0
added 15 packages
```

## Step 2: Configuration

Create a config file `config.json`:

```json
{
  "apiKey": "your-api-key",
  "environment": "development"
}
```

## Step 3: Basic Usage

Create a new file `app.ts`:

```typescript
import { Client } from 'package-name';

const client = new Client({
  apiKey: process.env.API_KEY
});

async function main() {
  const result = await client.doSomething();
  console.log(result);
}

main();
```

Run it:
```bash
npm run start
```

Expected output:
```
{ success: true, data: [...] }
```

## Step 4: Advanced Features

[More complex examples]

## Common Issues

### Issue: "API key invalid"

**Cause**: API key not properly configured

**Solution**:
1. Check your .env file
2. Verify the key format
3. Ensure no extra whitespace

### Issue: "Connection timeout"

**Cause**: Network or firewall issues

**Solution**:
1. Check internet connection
2. Verify firewall settings
3. Try increasing timeout value

## Next Steps

- Read the [API Reference](./API.md)
- Check out [Advanced Topics](./ADVANCED.md)
- Join our [Discord community](https://discord.gg/...)

## Related Guides

- [Authentication Guide](./AUTH.md)
- [Deployment Guide](./DEPLOY.md)
```


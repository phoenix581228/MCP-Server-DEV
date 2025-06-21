#\!/usr/bin/env node
process.env.PERPLEXITY_API_KEY = 'invalid-key';
process.env.PERPLEXITY_MODEL = 'wrong-model';
process.env.DEBUG = 'true';

import('./dist/index.js').then(() => {
  console.log('Server started');
  setTimeout(() => process.exit(0), 1000);
}).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
EOF < /dev/null
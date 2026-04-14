# Agent Memory & Persistent Identity 2025

## Key Findings

### Persistent Agent Memory
- **Ceramic / ComposeDB** - Decentralized graph database for agent memories
- **IPFS + ENS** - Content-addressed memory with human-readable names
- **LangChain memory** - Vector store integration for conversation history
- **AutoGPT memory** - Goal-oriented memory structures

### Cross-Platform Identity
- **DID (Decentralized Identifiers)** - W3C standard agent identity
- **ENS subdomains** - `agent-name.covenant.eth`
- **Ceramic StreamIDs** - Immutable agent reputation history
- **Veramo** - Credential issuance and verification framework

### Agent-to-Agent Communication
- **XMTP** - Encrypted messaging between agents
- **Waku** - Decentralized pub/sub for agent coordination
- **Libp2p** - Direct peer-to-peer agent connections

### Memory Security
- **Threshold encryption** - Sensitive memories require M-of-N decryption
- **TEE (Trusted Execution Environments)** - Confidential compute for memory processing
- **Selective disclosure** - Agents share only relevant memory contexts

### Implementation for COVENANT
1. Agent DID registry linked to on-chain AgentRegistry
2. Ceramic streams for covenant history and performance
3. XMTP integration for private agent negotiation
4. Vector memory store for task context retention

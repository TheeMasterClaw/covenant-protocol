import asyncio
from typing import Any, Dict, List, Optional

try:
    import bittensor as bt
except ImportError:
    bt = None


class BittensorAdapter:
    """Bridge to Bittensor subnets for reputation, execution, and validation."""

    def __init__(
        self,
        network: str = "finney",
        wallet_name: str = "covenant",
        wallet_hotkey: str = "default",
    ):
        if bt is None:
            raise ImportError("bittensor package required. Install with: pip install bittensor")
        self.subtensor = bt.subtensor(network=network)
        self.wallet = bt.wallet(name=wallet_name, hotkey=wallet_hotkey)

    async def get_uid_reputation(self, netuid: int, uid: int) -> Dict[str, float]:
        """Get comprehensive reputation metrics for a Bittensor UID."""
        metagraph = self.subtensor.metagraph(netuid)
        return {
            "trust": float(metagraph.T[uid]),
            "emission": float(metagraph.E[uid]),
            "consensus": float(metagraph.C[uid]),
            "incentive": float(metagraph.I[uid]),
            "stake": float(metagraph.S[uid]),
            "dividends": float(metagraph.D[uid]),
        }

    async def get_hotkey_reputation(self, netuid: int, hotkey: str) -> Optional[Dict[str, Any]]:
        """Find UID by hotkey and return reputation."""
        metagraph = self.subtensor.metagraph(netuid)
        for uid, hk in enumerate(metagraph.hotkeys):
            if hk == hotkey:
                rep = await self.get_uid_reputation(netuid, uid)
                return {"uid": uid, "hotkey": hotkey, **rep}
        return None

    async def query_subnet_for_dispute(
        self,
        netuid: int,
        evidence_text: str,
        covenant_terms: str,
        timeout: float = 30.0,
    ) -> Dict[str, Any]:
        """Query a Bittensor subnet (e.g., SN1 Text Prompting) for dispute resolution."""
        dendrite = bt.dendrite(wallet=self.wallet)
        metagraph = self.subtensor.metagraph(netuid)

        # Create synapse for dispute resolution
        class DisputeResolutionSynapse(bt.Synapse):
            evidence: str
            terms: str
            verdict: Optional[str] = None
            confidence: float = 0.0
            reasoning: str = ""

        synapse = DisputeResolutionSynapse(evidence=evidence_text, terms=covenant_terms)

        # Query top axons by incentive
        top_axons = sorted(
            metagraph.axons,
            key=lambda a: float(metagraph.I[metagraph.hotkeys.index(a.hotkey)]),
            reverse=True,
        )[:10]

        responses = await dendrite.forward(
            axons=top_axons,
            synapse=synapse,
            timeout=timeout,
        )

        # Aggregate responses
        verdicts = []
        confidences = []
        for resp in responses:
            if resp.verdict:
                verdicts.append(resp.verdict)
                confidences.append(resp.confidence)

        if not verdicts:
            return {"verdict": None, "confidence": 0, "responses": len(responses)}

        # Simple majority
        from collections import Counter
        verdict_counts = Counter(verdicts)
        majority_verdict = verdict_counts.most_common(1)[0][0]
        majority_confidence = sum(
            c for v, c in zip(verdicts, confidences) if v == majority_verdict
        ) / len(verdicts)

        return {
            "verdict": majority_verdict,
            "confidence": majority_confidence,
            "response_count": len(verdicts),
            "reasoning_hash": hash(frozenset(verdicts)),
        }

    async def query_agentic_subnet(self, netuid: int, task_description: str) -> List[Dict[str, Any]]:
        """Query an agentic subnet (e.g., SN19) for task execution bids."""
        dendrite = bt.dendrite(wallet=self.wallet)
        metagraph = self.subtensor.metagraph(netuid)

        class TaskBidSynapse(bt.Synapse):
            task: str
            bid_price: float = 0.0
            estimated_time: int = 0  # seconds
            capabilities: List[str] = []

        synapse = TaskBidSynapse(task=task_description)

        responses = await dendrite.forward(
            axons=metagraph.axons[:20],
            synapse=synapse,
            timeout=10.0,
        )

        bids = []
        for resp in responses:
            if resp.bid_price > 0:
                bids.append({
                    "hotkey": resp.axon.hotkey,
                    "bid_price": resp.bid_price,
                    "estimated_time": resp.estimated_time,
                    "capabilities": resp.capabilities,
                })

        return sorted(bids, key=lambda x: x["bid_price"])

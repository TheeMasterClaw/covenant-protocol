import { BigInt } from "@graphprotocol/graph-ts";
import {
  DisputeCreated,
  JurorAdded,
  JurorRemoved,
  DAOPaused,
  DAOUnpaused,
  VotingParametersUpdated,
} from "../generated/DisputeDAO/DisputeDAO";
import { Dispute, DisputeDAO, JurorProfile } from "../generated/schema";

function getOrCreateDAO(): DisputeDAO {
  let dao = DisputeDAO.load("dao");
  if (!dao) {
    dao = new DisputeDAO("dao");
    dao.address = new BigInt(0) as any;
    dao.name = "COVENANT Dispute DAO";
    dao.totalDisputes = BigInt.zero();
    dao.totalResolved = BigInt.zero();
    dao.totalAppealed = BigInt.zero();
    dao.activeJurors = BigInt.zero();
    dao.minJurySize = BigInt.fromI32(5);
    dao.votingPeriod = BigInt.fromI32(86400);
    dao.appealPeriod = BigInt.fromI32(172800);
    dao.evidencePeriod = BigInt.fromI32(604800);
    dao.quorumBps = BigInt.fromI32(5100);
    dao.paused = false;
    dao.save();
  }
  return dao;
}

export function handleDisputeCreated(event: DisputeCreated): void {
  let dao = getOrCreateDAO();
  dao.totalDisputes = dao.totalDisputes.plus(BigInt.fromI32(1));
  dao.save();

  let dispute = new Dispute(event.params.disputeId.toString());
  dispute.disputeId = event.params.disputeId;
  dispute.covenant = event.params.covenant;
  dispute.taskId = event.params.taskId;
  dispute.initiator = event.params.initiator;
  dispute.respondent = event.params.respondent;
  dispute.reason = event.params.reason;
  dispute.status = "OPEN";
  dispute.category = "GENERAL";
  dispute.createdAt = event.block.timestamp;
  dispute.evidenceDeadline = event.block.timestamp.plus(dao.evidencePeriod);
  dispute.jurySize = BigInt.zero();
  dispute.minStakeToVote = BigInt.zero();
  dispute.totalEvidence = BigInt.zero();
  dispute.totalVotes = BigInt.zero();
  dispute.votesForInitiator = BigInt.zero();
  dispute.votesForRespondent = BigInt.zero();
  dispute.appealCount = BigInt.zero();
  dispute.penaltyAmount = BigInt.zero();
  dispute.chainId = BigInt.fromI32(1);
  dispute.blockNumber = event.block.number;
  dispute.transactionHash = event.transaction.hash;
  dispute.save();
}

export function handleJurorAdded(event: JurorAdded): void {
  let dao = getOrCreateDAO();
  dao.activeJurors = dao.activeJurors.plus(BigInt.fromI32(1));
  dao.save();

  let juror = JurorProfile.load(event.params.juror.toHex());
  if (!juror) {
    juror = new JurorProfile(event.params.juror.toHex());
    juror.juror = event.params.juror;
    juror.totalCases = BigInt.zero();
    juror.totalVotes = BigInt.zero();
    juror.correctVotes = BigInt.zero();
    juror.totalStaked = event.params.stakeAmount;
    juror.totalEarned = BigInt.zero();
    juror.active = true;
    juror.reputationScore = BigInt.fromI32(100);
    juror.joinedAt = event.block.timestamp;
    juror.lastActivityAt = event.block.timestamp;
    juror.save();
  }
}

export function handleJurorRemoved(event: JurorRemoved): void {
  let dao = getOrCreateDAO();
  dao.activeJurors = dao.activeJurors.minus(BigInt.fromI32(1));
  dao.save();

  let juror = JurorProfile.load(event.params.juror.toHex());
  if (juror) {
    juror.active = false;
    juror.lastActivityAt = event.block.timestamp;
    juror.save();
  }
}

export function handleDAOPaused(event: DAOPaused): void {
  let dao = getOrCreateDAO();
  dao.paused = true;
  dao.save();
}

export function handleDAOUnpaused(event: DAOUnpaused): void {
  let dao = getOrCreateDAO();
  dao.paused = false;
  dao.save();
}

export function handleVotingParametersUpdated(event: VotingParametersUpdated): void {
  let dao = getOrCreateDAO();
  dao.minJurySize = event.params.minJurySize;
  dao.votingPeriod = event.params.votingPeriod;
  dao.appealPeriod = event.params.appealPeriod;
  dao.evidencePeriod = event.params.evidencePeriod;
  dao.save();
}

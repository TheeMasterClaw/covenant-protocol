import {
  BigInt,
  Bytes,
  Address,
  ethereum,
} from "@graphprotocol/graph-ts";
import {
  CovenantFactory,
  CovenantCreated,
  ImplementationUpgraded,
  Paused,
  Unpaused,
} from "../generated/CovenantFactory/CovenantFactory";
import { CovenantFactory as FactoryEntity, Covenant, User, CovenantEvent } from "../generated/schema";

export function handleCovenantCreated(event: CovenantCreated): void {
  let factory = FactoryEntity.load("factory");
  if (!factory) {
    factory = new FactoryEntity("factory");
    factory.address = event.address;
    factory.implementation = Bytes.empty();
    factory.totalCovenants = BigInt.zero();
    factory.version = BigInt.fromI32(1);
    factory.paused = false;
  }
  factory.totalCovenants = factory.totalCovenants.plus(BigInt.fromI32(1));
  factory.save();

  let creator = User.load(event.params.creator.toHex());
  if (!creator) {
    creator = new User(event.params.creator.toHex());
    creator.address = event.params.creator;
    creator.createdAt = event.block.timestamp;
    creator.totalCovenants = BigInt.zero();
    creator.totalTasks = BigInt.zero();
  }
  creator.totalCovenants = creator.totalCovenants.plus(BigInt.fromI32(1));
  creator.save();

  let covenant = new Covenant(event.params.covenantAddress.toHex());
  covenant.address = event.params.covenantAddress;
  covenant.creator = event.params.creator;
  covenant.name = event.params.name;
  covenant.description = "";
  covenant.termsHash = Bytes.empty();
  covenant.createdAt = event.block.timestamp;
  covenant.updatedAt = event.block.timestamp;
  covenant.status = "PENDING";
  covenant.chainId = event.params.chainId;
  covenant.version = BigInt.fromI32(1);
  covenant.implementation = factory.implementation;
  covenant.totalValueLocked = BigInt.zero();
  covenant.transactionCount = BigInt.zero();
  covenant.save();

  let covenantEvent = new CovenantEvent(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString()
  );
  covenantEvent.covenant = covenant.id;
  covenantEvent.eventType = "CovenantCreated";
  covenantEvent.emitter = event.address;
  covenantEvent.data = event.params.name;
  covenantEvent.blockNumber = event.block.number;
  covenantEvent.blockTimestamp = event.block.timestamp;
  covenantEvent.transactionHash = event.transaction.hash;
  covenantEvent.save();
}

export function handleImplementationUpgraded(event: ImplementationUpgraded): void {
  let factory = FactoryEntity.load("factory");
  if (factory) {
    factory.implementation = event.params.newImplementation;
    factory.version = factory.version.plus(BigInt.fromI32(1));
    factory.save();
  }
}

export function handlePaused(event: Paused): void {
  let factory = FactoryEntity.load("factory");
  if (factory) {
    factory.paused = true;
    factory.save();
  }
}

export function handleUnpaused(event: Unpaused): void {
  let factory = FactoryEntity.load("factory");
  if (factory) {
    factory.paused = false;
    factory.save();
  }
}

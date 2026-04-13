import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  // Create sample users
  const user1 = await prisma.user.upsert({
    where: { address: "0x1234567890123456789012345678901234567890" },
    update: {},
    create: {
      address: "0x1234567890123456789012345678901234567890",
      ensName: "alice.covenant.eth",
      totalCovenants: 1,
      totalTasks: 2,
    },
  });

  const user2 = await prisma.user.upsert({
    where: { address: "0x0987654321098765432109876543210987654321" },
    update: {},
    create: {
      address: "0x0987654321098765432109876543210987654321",
      ensName: "bob.covenant.eth",
      totalCovenants: 1,
      totalTasks: 1,
    },
  });

  // Create sample covenant
  const covenant = await prisma.covenant.upsert({
    where: { address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd" },
    update: {},
    create: {
      address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      creatorAddress: user1.address,
      name: "Developer Guild",
      description: "A covenant for software developers",
      termsHash: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      chainId: 196,
      status: "ACTIVE",
      implementation: "0x1111111111111111111111111111111111111111",
      totalValueLocked: 1000000000000000000n.toString(), // 1 ETH
    },
  });

  // Create participant relationships
  await prisma.covenantParticipant.upsert({
    where: {
      covenantId_userId: {
        covenantId: covenant.id,
        userId: user1.id,
      },
    },
    update: {},
    create: {
      covenantId: covenant.id,
      userId: user1.id,
      role: "OWNER",
      stakeAmount: 500000000000000000n.toString(), // 0.5 ETH
    },
  });

  await prisma.covenantParticipant.upsert({
    where: {
      covenantId_userId: {
        covenantId: covenant.id,
        userId: user2.id,
      },
    },
    update: {},
    create: {
      covenantId: covenant.id,
      userId: user2.id,
      role: "MEMBER",
      stakeAmount: 250000000000000000n.toString(), // 0.25 ETH
    },
  });

  // Create sample tasks
  await prisma.task.createMany({
    skipDuplicates: true,
    data: [
      {
        onChainTaskId: "1",
        covenantId: covenant.id,
        creatorId: user1.id,
        assigneeId: user2.id,
        title: "Implement subgraph mappings",
        description: "Create TheGraph mappings for covenant events",
        reward: 100000000000000000n.toString(), // 0.1 ETH
        deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        status: "ASSIGNED",
        chainId: 196,
        priority: 2,
      },
      {
        onChainTaskId: "2",
        covenantId: covenant.id,
        creatorId: user1.id,
        title: "Write documentation",
        description: "Document the covenant API endpoints",
        reward: 50000000000000000n.toString(), // 0.05 ETH
        deadline: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days
        status: "OPEN",
        chainId: 196,
        priority: 1,
      },
    ],
  });

  // Create reputation scores
  await prisma.reputationScore.upsert({
    where: { userId: user1.id },
    update: {},
    create: {
      userId: user1.id,
      score: 850,
      tier: "EXPERT",
      stakedAmount: 500000000000000000n.toString(),
      totalTasksCompleted: 15,
      totalTasksCreated: 8,
      averageRating: 4.8,
    },
  });

  await prisma.reputationScore.upsert({
    where: { userId: user2.id },
    update: {},
    create: {
      userId: user2.id,
      score: 650,
      tier: "JOURNEYMAN",
      stakedAmount: 250000000000000000n.toString(),
      totalTasksCompleted: 8,
      totalTasksCreated: 3,
      averageRating: 4.5,
    },
  });

  console.log("Seeding completed!");
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

from typing import List
from fastapi import APIRouter, HTTPException, Request, status, BackgroundTasks

from app.schemas.task import TaskCreate, TaskResponse, TaskStatus
from core.tasks import TaskQueue

router = APIRouter()


@router.get("", response_model=List[TaskResponse])
async def list_tasks(request: Request, status: TaskStatus = None, agent_id: str = None):
    queue: TaskQueue = request.app.state.task_queue
    tasks = queue.list_tasks(status=status, agent_id=agent_id)
    return tasks


@router.post("/assign", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def assign_task(request: Request, task_in: TaskCreate):
    coordinator = request.app.state.coordinator
    try:
        task = await coordinator.assign_task(
            task_type=task_in.task_type,
            payload=task_in.payload,
            priority=task_in.priority,
            preferred_agent=task_in.preferred_agent,
        )
        return task
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(request: Request, task_id: str):
    coordinator = request.app.state.coordinator
    task = coordinator.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.get("/{task_id}/status")
async def get_task_status(request: Request, task_id: str):
    coordinator = request.app.state.coordinator
    status = coordinator.get_task_status(task_id)
    if not status:
        raise HTTPException(status_code=404, detail="Task not found")
    return status


@router.post("/{task_id}/cancel")
async def cancel_task(request: Request, task_id: str):
    coordinator = request.app.state.coordinator
    success = coordinator.cancel_task(task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found or already completed")
    return {"status": "cancelled"}


@router.post("/{task_id}/retry")
async def retry_task(request: Request, task_id: str, background_tasks: BackgroundTasks):
    coordinator = request.app.state.coordinator
    try:
        task = coordinator.retry_task(task_id)
        return task
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

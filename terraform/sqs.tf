resource "aws_sqs_queue" "ecs_v3_queue" {
  name = "ecs-v3-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ecs_v3_queue_deadletter.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "ecs_v3_queue_deadletter" {
  name = "ecs-v3-queue-deadletter"
}

resource "aws_sqs_queue_redrive_allow_policy" "ecs_v3_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.ecs_v3_queue_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.ecs_v3_queue.arn]
  })
}

locals { topics = ["etl-htx","etl-coingecko","etl-cryptopanic","etl-user-uploads"] }
resource "google_pubsub_topic" "topics" { for_each = toset(local.topics) name = each.value }
output "topics" { value = { for k, v in google_pubsub_topic.topics : k => v.name } }

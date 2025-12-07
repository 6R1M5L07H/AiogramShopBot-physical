from enum import Enum


class WebhookMode(Enum):
    """
    Webhook mode configuration for bot operation.

    WEBHOOK: Telegram pushes updates to bot (requires public HTTPS endpoint)
    POLLING: Bot polls Telegram API for updates (no public endpoint needed)
    """
    WEBHOOK = "webhook"
    POLLING = "polling"

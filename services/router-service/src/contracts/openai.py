from pydantic import BaseModel, Field
from typing import Any, List, Optional, Dict

class ChatMessage(BaseModel):
    role: str
    content: str | List[Dict[str, Any]]

class ChatCompletionsRequest(BaseModel):
    model: Optional[str] = None
    messages: List[ChatMessage]
    max_tokens: Optional[int] = Field(default=None, ge=1)
    temperature: Optional[float] = None
    stream: Optional[bool] = False
    # allow unknown fields without breaking
    class Config:
        extra = "allow"

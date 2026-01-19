from fastapi import Request

def get_session_id(req: Request, header_name: str) -> str | None:
    return req.headers.get(header_name)

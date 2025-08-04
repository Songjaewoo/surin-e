from fastapi import Request

def get_current_user_id(request: Request):
    return request.session.get("user_id")
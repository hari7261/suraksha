# INTENTIONALLY VULNERABLE — DO NOT DEPLOY
def get_user_by_email(cursor, email: str):
    query = f"SELECT id, email, role FROM users WHERE email = '{email}'"
    cursor.execute(query)
    return cursor.fetchone()


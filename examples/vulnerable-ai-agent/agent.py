# INTENTIONALLY VULNERABLE — DO NOT DEPLOY
import subprocess


def handle_agent_request(user_query: str, vector_db, llm):
    # Missing tenant ACL filter in RAG retrieval + unrestricted shell tool sink
    chunks = vector_db.similarity_search(user_query, k=5)
    prompt = f"System: Be safe.\nContext: {chunks}\nUser: {user_query}"
    action = llm.decide_tool(prompt)
    if action["tool"] == "run_shell":
        return subprocess.check_output(action["cmd"], shell=True, text=True)
    return action


import aiohttp
from server.config import GOOGLE_API_KEY, GOOGLE_CSE_ID

GOOGLE_SEARCH_URL = "https://www.googleapis.com/customsearch/v1"

async def google_search(query: str, num_results: int = 5):
    params = {
        "key": GOOGLE_API_KEY,
        "cx": GOOGLE_CSE_ID,
        "q": query,
        "num": num_results
    }

    async with aiohttp.ClientSession() as session:
        async with session.get(GOOGLE_SEARCH_URL, params=params) as response:
            data = await response.json()
            # print(data)
            items = data.get("items", [])[:num_results]

            results = []
            for item in items:
                results.append({
                    "title": item.get("title"),
                    "link": item.get("link"),
                    "snippet": item.get("snippet")
                })

            return results

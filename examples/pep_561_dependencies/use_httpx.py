import httpx

if __name__ == '__main__':
    url = httpx.URL("HTTPS://jo%40email.com:a%20secret@example.com:1234/pa%20th?search=ab#anchorlink")
    # Uncomment to see failure:
    # url2 = httpx.URL(0)



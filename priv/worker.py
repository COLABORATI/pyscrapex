from erlport import erlang


def send_new_urls(urls):
    mod = "Elixir.Downloader.Server"
    erlang.call(mod, "download_urls", [urls])


def process_response(response):
    # response looks like this:
    # [("headers", [...]), ("body", [...]), ...]
    response = dict(response)
    more_urls = _do_some_real_processing(response["body"])
    if more_urls:
        send_new_urls(more_urls)


def _do_some_real_processing(response_html):
    for line in response_html.splitlines():
        pass
    # print line[:10]

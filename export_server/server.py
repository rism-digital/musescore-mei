from sanic import Sanic, response, request
import verovio


app = Sanic("export-server")


@app.post("/mei")
async def convert(req):
    if "content" not in req.files:
        return response.text("No file attachment was found.", status=400)

    uploaded_file: request.File = req.files.get("content")
    file_data: str = uploaded_file.body.decode("utf-8")
    if not file_data:
        return response.text("No data was found in the file attachment.", status=400)

    vrv_tk = verovio.toolkit()
    loaded: bool = vrv_tk.loadData(file_data)
    if not loaded:
        return response.text("Verovio could not load the file.", status=400)

    basic_q: str = req.args.get("basic", "false")
    basic: bool
    if basic_q == "true":
        basic = True
    else:
        basic = False

    mei: str = vrv_tk.getMEI({"basic": basic})
    return response.text(mei, headers={"Content-Type": "application/xml+mei"})

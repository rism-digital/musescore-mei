from sanic import Sanic, response, request
import verovio


app = Sanic("export-server")


@app.post("/mei")
async def convert(req):
    vrv_tk = verovio.toolkit()
    uploaded_file: request.File = req.files.get("content")
    vrv_tk.loadData(uploaded_file.body.decode("utf-8"))

    mei = vrv_tk.getMEI({})
    return response.text(mei, headers={"Content-Type": "application/xml+mei"})

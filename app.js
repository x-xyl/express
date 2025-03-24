const path = require('path');
const express = require('express');
const app = express();
constcookieParser = require('cookie-parser');
app.set('view engine', 'pug')
app.use(express.static('public'));
app.use('/css', express.static(__dirname + '/public/css'));
app.set('views', path.join(__dirname, 'views'))

const myMiddleware = (req, res, next) => {
    req.locals.name = 'Flavio'
    /* ... */
    next()
  }
app.get('/about', (req, res) => {
    res.render('about',{name:'john'})
  })

  app.get('/home',myMiddleware, (req, res) => {
     res.render('home',{sayHello:sayHello})
  })

app.listen(3000, () => {
    console.log('Server is running on port 3000')
})
app.get('/getFile',(req,res)=>{
    res.download(path.join(__dirname, '/Desktop.pem'),'myFile.pem', (err) => {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }
        console.log('File is downloaded');
    })
})



sayHello=()=>{
    return "Hello this is home page"
}

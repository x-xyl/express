const path = require('path');
const express = require('express');
const app = express();

app.set('view engine', 'pug')
app.use(express.static('public'));
app.use('/css', express.static(__dirname + '/public/css'));
app.set('views', path.join(__dirname, 'views'))
app.get('/about', (req, res) => {
    res.render('about',{name:'john'})
  })

  app.get('/home', (req, res) => {
     res.render('home',{sayHello:sayHello})
  })

app.listen(3000, () => {
    console.log('Server is running on port 3000')
})

sayHello=()=>{
    return "Hello this is home page"
}

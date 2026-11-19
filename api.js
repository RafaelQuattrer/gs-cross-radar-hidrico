// Serviço HTTP da fotografia pública. Nenhum dado pessoal é recebido.
const http=require('node:http');const fs=require('node:fs');const path=require('node:path');
const body=fs.readFileSync(path.join(__dirname,'assets','territorio.json'));
http.createServer((req,res)=>{
 res.setHeader('Access-Control-Allow-Origin','*');
 if(req.url==='/api/territorio'){res.writeHead(200,{'Content-Type':'application/json; charset=utf-8'});res.end(body);}
 else{res.writeHead(404);res.end('Rota não encontrada');}
}).listen(3001,'0.0.0.0',()=>console.log('API local em http://localhost:3001/api/territorio'));

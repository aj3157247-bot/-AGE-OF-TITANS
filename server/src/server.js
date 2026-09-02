import express from 'express';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer } from 'ws';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataFile = path.join(__dirname, '..', 'data', 'db.json');
const app = express();
app.use(cors());
app.use(express.json({limit:'64kb'}));

function load(){ return JSON.parse(fs.readFileSync(dataFile,'utf8')); }
function save(db){ fs.writeFileSync(dataFile, JSON.stringify(db,null,2)); }
function id(){ return crypto.randomUUID(); }
function safePlayer(p){ return {id:p.id,name:p.name,trophies:p.trophies,gold:p.gold,food:p.food,crystals:p.crystals,power:p.power}; }

app.get('/health',(req,res)=>res.json({ok:true,game:'AGE OF TITANS'}));
app.post('/api/register',(req,res)=>{
  const name=String(req.body?.name||'Commander').slice(0,24);
  const db=load(); const player={id:id(),name,trophies:1200,gold:12500,food:9200,crystals:240,power:1000};
  db.players[player.id]=player; save(db); res.json({player:safePlayer(player)});
});
app.get('/api/player/:id',(req,res)=>{
  const p=load().players[req.params.id]; if(!p) return res.status(404).json({error:'player_not_found'});
  res.json({player:safePlayer(p)});
});
app.post('/api/search',(req,res)=>{
  const db=load(); const me=db.players[req.body?.playerId];
  if(!me) return res.status(404).json({error:'player_not_found'});
  const candidates=Object.values(db.players).filter(p=>p.id!==me.id && Math.abs(p.trophies-me.trophies)<=500);
  const fallback={id:'npc-'+Date.now(),name:['Iron Dominion','Crimson Horde','Wolf Kingdom','Dragon Pact'][Math.floor(Math.random()*4)],trophies:me.trophies+Math.floor(Math.random()*401)-200,power:Math.max(500,me.power+Math.floor(Math.random()*12000)-6000),gold:0,food:0,crystals:0};
  const target=candidates.length?candidates[Math.floor(Math.random()*candidates.length)]:fallback;
  res.json({target:safePlayer(target),isNpc:!target.id || String(target.id).startsWith('npc-')});
});
app.post('/api/raid/result',(req,res)=>{
  const db=load(); const p=db.players[req.body?.playerId]; if(!p) return res.status(404).json({error:'player_not_found'});
  const stars=Math.max(0,Math.min(3,Number(req.body?.stars)||0));
  const loot=Math.max(0,Math.min(100000,Number(req.body?.loot)||0));
  p.gold+=Math.floor(loot); p.food+=Math.floor(loot*.7); p.trophies=Math.max(0,p.trophies+stars*28-20); save(db);
  res.json({player:safePlayer(p),result:{stars,loot}});
});

const server=app.listen(process.env.PORT||8080,()=>console.log(`AGE OF TITANS server listening on ${process.env.PORT||8080}`));
const wss=new WebSocketServer({server,path:'/ws'});
wss.on('connection',ws=>{ ws.send(JSON.stringify({type:'welcome',game:'AGE OF TITANS'})); });

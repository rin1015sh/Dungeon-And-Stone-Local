// 웹 키 넘기기(export_presets.cfg html/head_include에 한 줄로 넣는다 — 고치면 python으로 다시 넣는다, DEPLOY.md §3).
// 게임 화면(canvas) 밖으로 간 키 · code가 빈 키(iPad Safari) · 한글 자판 글자(ㅈ → W)를 canvas로 다시 보낸다. 주소 뒤 ?keys = 받은 키를 화면 아래에 보인다.
(function(){
var HAN='ㅂqㅈwㄷeㄱrㅅtㅛyㅕuㅑiㅐoㅔpㅁaㄴsㅇdㄹfㅎgㅗhㅓjㅏkㅣlㅋzㅌxㅊcㅍvㅠbㅜnㅡmㅃqㅉwㄸeㄲrㅆtㅒoㅖp';
var NAMED={'Enter':'Enter','Escape':'Escape','Esc':'Escape','UIKeyInputEscape':'Escape','Tab':'Tab',' ':'Space','Spacebar':'Space','Backspace':'Backspace',
'ArrowUp':'ArrowUp','UIKeyInputUpArrow':'ArrowUp','ArrowDown':'ArrowDown','UIKeyInputDownArrow':'ArrowDown','ArrowLeft':'ArrowLeft','UIKeyInputLeftArrow':'ArrowLeft',
'ArrowRight':'ArrowRight','UIKeyInputRightArrow':'ArrowRight','`':'Backquote','~':'Backquote','₩':'Backquote','F1':'F1','UIKeyInputF1':'F1','[':'BracketLeft','{':'BracketLeft',']':'BracketRight','}':'BracketRight'};
var mine=new WeakSet();
var cv=function(){return document.getElementById('canvas');};
var fix=function(e){
 var k=e.key||'';
 if(NAMED[k])return {code:NAMED[k],key:k.indexOf('UIKeyInput')===0?NAMED[k]:k};
 if(k.length===1){var l=k.toLowerCase();var i=HAN.indexOf(k);if(i>=0&&i%2===0)l=HAN.charAt(i+1);
  if(l>='a'&&l<='z')return {code:'Key'+l.toUpperCase(),key:l};if(l>='0'&&l<='9')return {code:'Digit'+l,key:l};}
 return null;};
var dbg=null;
if(location.search.indexOf('keys')>=0){window.addEventListener('load',function(){dbg=document.createElement('div');
 dbg.style.cssText='position:fixed;left:0;bottom:0;z-index:9;background:#000c;color:#fff;font:14px monospace;padding:4px;pointer-events:none';document.body.appendChild(dbg);});}
var on=function(e){
 if(mine.has(e))return;
 var c=cv();if(!c)return;
 var t=e.target;if(t&&(t.tagName==='INPUT'||t.tagName==='TEXTAREA')&&t!==c&&!t.closest('#canvas'))return;
 var good=e.code&&e.code!=='Unidentified';
 var f=good?{code:e.code,key:e.key}:fix(e);
 if(dbg)dbg.textContent=e.type+' key='+JSON.stringify(e.key)+' code='+JSON.stringify(e.code)+' kc='+e.keyCode+' target='+(t&&(t.id||t.tagName))+' -> '+(f?f.code:'-');
 if(good&&t===c)return;
 if(!f)return;
 e.preventDefault();e.stopImmediatePropagation();
 if(document.activeElement!==c)c.focus();
 var n=new KeyboardEvent(e.type,{key:f.key,code:f.code,location:e.location,repeat:e.repeat,ctrlKey:e.ctrlKey,shiftKey:e.shiftKey,altKey:e.altKey,metaKey:e.metaKey,bubbles:true,cancelable:true});
 mine.add(n);c.dispatchEvent(n);};
window.addEventListener('keydown',on,true);window.addEventListener('keyup',on,true);
var foc=function(){var c=cv();if(c)c.focus();};
document.addEventListener('touchstart',foc,{passive:true});document.addEventListener('pointerdown',foc,true);
})();

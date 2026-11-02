import test from 'node:test';
import assert from 'node:assert/strict';
import {googleSignInOptions,finishGoogleSignIn} from './oauth.js';
test('Google callback is restricted to current origin root',()=>{
 const options=googleSignInOptions('https://admin.example/path?next=https://evil.example');
 assert.equal(options.provider,'google');assert.equal(options.options.redirectTo,'https://admin.example/');
 assert.throws(()=>googleSignInOptions('http://admin.example'));
});
test('callback exchanges once and removes credentials',async()=>{
 let called=0,clean='';await finishGoogleSignIn({exchangeCodeForSession:async code=>{called++;assert.equal(code,'one-use');return {error:null};}},'https://admin.example/?code=one-use&state=private',v=>clean=v);
 assert.equal(called,1);assert.equal(clean,'/');
});
test('denied sign-in never exchanges and cleans error URL',async()=>{
 let clean='';await assert.rejects(finishGoogleSignIn({exchangeCodeForSession:()=>assert.fail()},'https://admin.example/?error=access_denied&error_description=private',v=>clean=v),/cancelled/);assert.equal(clean,'/');
});
test('failed exchange cleans URL and presents a retry instruction',async()=>{
 let clean='';await assert.rejects(finishGoogleSignIn({exchangeCodeForSession:async()=>({error:new Error('internal')})},'https://admin.example/?code=expired',v=>clean=v),/Start Google sign-in again/);assert.equal(clean,'/');
});

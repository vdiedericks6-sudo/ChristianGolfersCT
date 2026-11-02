import test from 'node:test';
import assert from 'node:assert/strict';
import {esc,csv,division,seasonRounds} from './domain.js';
test('database text cannot inject markup',()=>assert.equal(esc('<img onerror="x">'), '&lt;img onerror=&quot;x&quot;&gt;'));
test('exports escape quotes and neutralise spreadsheet formulas',()=>assert.equal(csv([['=SUM(A1)', 'a"b']]), '"\'=SUM(A1)","a""b"'));
test('manual division overrides index and blank uses automatic classification',()=>{assert.equal(division({handicap:30,league:'A'}),'A');assert.equal(division({handicap:null}),'Social');assert.equal(division({handicap:18}),'B');});
test('season cutoff uses South African date and keeps input history',()=>{const rounds=[{played_at:'2025-12-31T23:00:00Z'},{played_at:'2025-12-31T18:00:00Z'}];assert.equal(seasonRounds(rounds,2026).length,1);assert.equal(rounds.length,2);});

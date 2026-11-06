import React from 'react';
import { BrowserRouter } from 'react-router-dom';

export function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-slate-100">
        <header className="max-w-2xl text-center space-y-4">
          <h1 className="text-3xl font-extrabold text-blue-900 tracking-tight">
            MedPrepOS
          </h1>
          <p className="text-slate-600">
            Dedicated Learning Management & Assessment Platform for NEET-UG and IMAT Candidates.
          </p>
        </header>
      </div>
    </BrowserRouter>
  );
}


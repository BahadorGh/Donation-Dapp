import React from 'react';
import { Route, Routes } from 'react-router-dom';

import { Sidebar, Navbar } from './components';
import { CampaignDetails, CreateCampaign, UpdateCampaign , Home, Profile  } from './pages';

const App = () => {
  return (
    <div className="relative sm:-8 p-4 bg-[#13131a] min-h-screen flex flex-row ">
      <div className="sm:flex hidden mr-10 relative md:basis-1/4">
        <Sidebar />
      </div>

      <div className="flex-1 max-sm:w-full md:basis-3/6 mx-auto sm:pr-5">
        <Navbar />

        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/create-campaign" element={<CreateCampaign />} />
          <Route path="/campaign-details/:id" element={<CampaignDetails />} />
          <Route path="/campaign-update/:id" element={<UpdateCampaign />} />
        </Routes>
      </div>
    </div>
  )
}

export default App
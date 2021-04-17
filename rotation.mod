<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">   
  <UiMod name="Rotation" version="1.0.1" date="2021-04-17" >
    <Author name="Idrinth"/>
    <Description text="Automatically anounces rotation timers" />      
    <VersionSettings gameVersion="1.4.8" />      
    <Dependencies>         
      <Dependency name="EA_ChatWindow" />
      <Dependency name="LibSlash" />
      <Dependency name="AutoChannel" />
    </Dependencies>             
    <Files>         
      <File name="rotation.lua" />
      <File name="window.xml" />
    </Files>      
    <SavedVariables>
      <SavedVariable name="Rotation.Abilities"/>
    </SavedVariables>
    <OnInitialize>
      <CallFunction name="Rotation.OnInitialize" />
    </OnInitialize>
    <OnUpdate>
      <CallFunction name="Rotation.OnUpdate" />
    </OnUpdate>
    <OnShutdown/>
  </UiMod>
</ModuleFile>
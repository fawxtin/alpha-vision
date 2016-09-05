//+------------------------------------------------------------------+
//|                                                      Logging.mqh |
//|                                                          fawxtin |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "fawxtin"
#property link      "https://www.mql5.com"
#property strict


#ifndef __LOGGING__
#define __LOGGING__ 1


class Logging {
   protected:
      int m_fileHandler;
      
      static void checkFolder(string folder);
      static string findLogDir(string dirFilter);
      
   public:
      Logging(string logDir, string fname, int mode=FILE_CSV|FILE_WRITE) {
         m_fileHandler = FileOpen(StringFormat("%s\\%s", logDir, fname), mode);
      }
      
      void ~Logging() {
         if (m_fileHandler > 0) FileClose(m_fileHandler);
      }

      static string nextLogDir(string symbol);

      int getHandler() { return m_fileHandler; }
      
};

void Logging::checkFolder(string folder) {
   // check folders in symbol
   if (!FileIsExist(folder)) {
      int error = GetLastError();
      if (error != 5019) { // 5019 -> file is already a directory
         PrintFormat("[debug] creating folder: %s", folder);
         FolderCreate(folder);
      } else
         PrintFormat("[debug] folder already exists: %s", folder);
   } else
      PrintFormat("[debug] error, folder is already a common file: %s", folder);
}

string Logging::findLogDir(string dirSearch) {
   string lastDir = "";
   string curDir = "";
   bool searchContinuesP = true;

   long searchHandler = FileFindFirst(StringFormat("%s\\*", dirSearch), lastDir);   
   if (searchHandler == INVALID_HANDLE) searchContinuesP = false;
   while (searchContinuesP) {
      searchContinuesP = FileFindNext(searchHandler, curDir);
      if (curDir > lastDir) lastDir = curDir;
   }
   FileFindClose(searchHandler);
   
   if (lastDir == "") {
      return StringFormat("%s\\%03d", dirSearch, 1);
   } else {
      return StringFormat("%s\\%03d", dirSearch, StringToInteger(StringSubstr(lastDir, 0, StringLen(lastDir) - 1)) + 1);
   }
}

string Logging::nextLogDir(string symbol)  {
   checkFolder(symbol);
   string logDir = findLogDir(symbol);
   checkFolder(logDir);
         
   return logDir;
}

#endif

#property copyright "SeQuexCash"
#property link      "djeffersontrader@gmail.com"

enum TypeCandleStick {
   CAND_NONE,
   CAND_MARIBOZU,
   CAND_MARIBOZU_LONG,
   CAND_DOJI,
   CAND_SPIN_TOP,
   CAND_HAMMER,
   CAND_INVERT_HAMMER,
   CAND_LONG,
   CAND_SHORT,
   CAND_STAR
};

enum TypeTrend {
   UPPER,
   DOWN,
   LATERAL
};

struct CandleInfo {

   double open,high,low,close;
   datetime time;
   TypeTrend trend;
   bool bull;
   double bodysize;
   TypeCandleStick  type;
   double trendAvg;
   
   bool isTrendUpper(){
      return trend == UPPER;
   }
   
   bool isTrendDown(){
      return trend == DOWN;
   }

   bool isTrendLateral(){
      return trend == LATERAL;
   }

   bool isBull(){
      return !isDoji() && bull;
   }

   bool isDoji(){
      return type == CAND_DOJI;
   }
   
   bool isHammer(){
      return type == CAND_HAMMER;
   }
   
   bool isInvertedHammer(){
      return type == CAND_INVERT_HAMMER;
   }
   
   bool isMaribuzuLong(){
      return type == CAND_MARIBOZU_LONG;
   }
   
   bool isMaribuzu(){
      return type == CAND_MARIBOZU;
   }
   
   bool isLong(){
      return type == CAND_LONG;
   }
   
   bool isShort(){
      return type == CAND_SHORT;
   }
   
   bool isStar(){
      return type == CAND_STAR;
   }
   
   bool isSpinTop(){
      return type == CAND_SPIN_TOP;
   }
   
   bool isStrong(){
      return isMaribuzu() || isMaribuzuLong() || isLong();
   }
   
   bool isWeak(){
      return isDoji() || isShort();
   }
   
};

CandleInfo getCandleInfo(MqlRates &candle, int context_size) {
   MqlRates rates[];
   CopyRates(_Symbol, _Period, 0, context_size+1, rates);
   
   CandleInfo candleInfo;

   candleInfo.open = candle.open;
   candleInfo.high = candle.high;
   candleInfo.low = candle.low;
   candleInfo.close = candle.close;
   candleInfo.time = candle.time;

   double avg=0;
   for(int i=0;i<context_size;i++) {
      avg+=rates[i].close;
   }
   avg=avg/context_size;


   candleInfo.trendAvg = avg;

   if(avg<candleInfo.close) 
      candleInfo.trend=UPPER;

   if(avg>candleInfo.close) 
      candleInfo.trend=DOWN;

   if(avg==candleInfo.close) 
      candleInfo.trend=LATERAL;

   candleInfo.bull=candleInfo.open<candleInfo.close;

   candleInfo.bodysize=MathAbs(candleInfo.open-candleInfo.close);

   double shade_low=candleInfo.close-candleInfo.low;
   double shade_high=candleInfo.high-candleInfo.open;

   if(candleInfo.bull) {
      shade_low=candleInfo.open-candleInfo.low;
      shade_high=candleInfo.high-candleInfo.close;
   }

   double candleFullSize=candleInfo.high-candleInfo.low;

   double sum=0;
   for(int i=1; i<=context_size; i++)
      sum = sum + MathAbs(rates[i].open-rates[i].close);

   sum=sum/context_size;

   candleInfo.type=CAND_NONE;

   if(candleInfo.bodysize>sum*1.3) 
      candleInfo.type=CAND_LONG;

   if(candleInfo.bodysize<sum*0.5) 
      candleInfo.type=CAND_SHORT;

   if(candleInfo.bodysize<candleFullSize*0.03) 
      candleInfo.type=CAND_DOJI;

   if((shade_low<candleInfo.bodysize*0.01 || shade_high<candleInfo.bodysize*0.01) && candleInfo.bodysize>0) {
      if(candleInfo.type==CAND_LONG)
         candleInfo.type=CAND_MARIBOZU_LONG;
      else
         candleInfo.type=CAND_MARIBOZU;
   }

   if(shade_low>candleInfo.bodysize*2 && shade_high<candleInfo.bodysize*0.1) 
      candleInfo.type=CAND_HAMMER;

   if(shade_low<candleInfo.bodysize*0.1 && shade_high>candleInfo.bodysize*2) 
      candleInfo.type=CAND_INVERT_HAMMER;

   if(candleInfo.type==CAND_SHORT && shade_low>candleInfo.bodysize && shade_high>candleInfo.bodysize) 
      candleInfo.type=CAND_SPIN_TOP;

   return candleInfo;

}

bool isHammer(CandleInfo &candle){
   return candle.trend==DOWN && candle.type==CAND_HAMMER;
}

bool isHangingMan(CandleInfo &candle){
   return candle.trend==UPPER && candle.type==CAND_HAMMER;
}

bool isInvertedHammer(CandleInfo &candle){
   return candle.trend==DOWN && candle.type==CAND_INVERT_HAMMER;
}

bool isShootingStar(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==UPPER && candle2.trend==UPPER && candle1.type==CAND_INVERT_HAMMER) {
      if(candle2.close < candle1.open && candle2.close < candle1.close){
         return true;
      }
   }
   return false;
}


bool isBeltHoldBullish(CandleInfo &candle1, CandleInfo &candle2){
   // TESTAR MELHOR
   if(candle1.trend==DOWN 
         && candle2.bull  && !candle1.bull 
         && candle2.type==CAND_MARIBOZU_LONG 
         && candle1.bodysize<candle2.bodysize 
         && candle2.close<candle1.close) {
            return true;
        }
        return false;
}

bool isBeltHoldBearlish(CandleInfo &candle1, CandleInfo &candle2){
   // TESTAR MELHOR
   if(candle2.trend==UPPER
         && !candle2.bull && candle1.bull 
         && candle2.type==CAND_MARIBOZU_LONG 
         && candle1.bodysize<candle2.bodysize 
         && candle2.close>candle1.close) {
      return true;
   }
   return false;     
}

bool isEngulfingBullish(CandleInfo &candle1, CandleInfo &candle2){
      if(candle1.trend==DOWN && !candle1.bull && candle2.trend==DOWN && candle2.bull && 
         candle1.bodysize<candle2.bodysize &&
         candle1.close>=candle2.open && candle1.open<candle2.close) {
            return true;
      }
      return false;
}

bool isEngulfingBearlish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==UPPER && candle1.bull && candle2.trend==UPPER && !candle2.bull && 
      candle1.bodysize<candle2.bodysize &&
      candle1.close<=candle2.open && candle1.open>candle2.close) {
         return true;
   }
   return false;
}

bool isHaramiCrossBullish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==DOWN 
      && !candle1.bull 
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type==CAND_DOJI
      && candle1.close<=candle2.open 
      && candle1.close<=candle2.close 
      && candle1.open>candle2.close){
         return true;
   }
   return false;
}

bool isHaramiCrossBearlish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==UPPER 
      && candle1.bull 
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type==CAND_DOJI
      && candle1.close>=candle2.open 
      && candle1.close>=candle2.close 
      && candle1.close>=candle2.close){
         return true;
   }
   return false;
}


bool isHaramiBullish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==DOWN  
      && !candle1.bull
      && candle2.bull 
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type!=CAND_DOJI 
      && candle1.bodysize>candle2.bodysize 
      && candle1.close<=candle2.open 
      && candle1.close<=candle2.close 
      && candle1.open>candle2.close){
         return true;
   }
   return false;
}

bool isHaramiBearlish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==UPPER 
      && candle1.bull 
      && !candle2.bull 
      && (candle1.type==CAND_LONG|| candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type!=CAND_DOJI 
      && candle1.bodysize>candle2.bodysize 
      && candle1.trend==UPPER 
      && candle1.bull 
      && !candle2.bull 
      && (candle1.type==CAND_LONG|| candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type!=CAND_DOJI && candle1.bodysize>candle2.bodysize){
         return true;
   }
   return false;
}

bool isDojiStarBullish(CandleInfo &candle1, CandleInfo &candle2){
 if(candle1.trend==DOWN 
      && !candle1.bull
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type==CAND_DOJI
      && candle1.close>=candle2.open){
      return true;
   }
   return false;
}

bool isDojiStarBearlish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==UPPER 
      && candle1.bull 
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type==CAND_DOJI
      && candle1.close<=candle2.open){
      return true;
   }
   return false;
}

bool isPiercingLine(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==DOWN 
      && !candle1.bull 
      && candle2.trend==DOWN 
      && candle2.bull 
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && (candle2.type==CAND_LONG || candle2.type==CAND_MARIBOZU_LONG) 
      && (candle2.close>(candle1.close+candle1.open)/2)
      && candle1.close>=candle2.open 
      && candle2.close<=candle1.open) {
         return true;
   }
   return false;
}

bool isDarkCloudCover(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.trend==UPPER 
      && candle1.bull 
      && candle2.trend==UPPER 
      && !candle2.bull 
      && (candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG) 
      && (candle2.type==CAND_LONG || candle2.type==CAND_MARIBOZU_LONG) 
      && candle2.close<(candle1.close+candle1.open)/2
      && (candle1.close<=candle2.open && candle2.close>=candle1.open)){
         return true;   
      }
      return false;
}

bool isKickingBullish(CandleInfo &candle1, CandleInfo &candle2){
   if(!candle1.bull && candle2.bull 
      && candle1.type==CAND_MARIBOZU_LONG 
      && candle2.type==CAND_MARIBOZU_LONG 
      && candle1.open<candle2.open) {
         return true;
     }
     return false;
}

bool isKickingBearlish(CandleInfo &candle1, CandleInfo &candle2){
   if(candle1.bull 
      && !candle2.bull 
      && candle1.type==CAND_MARIBOZU_LONG 
      && candle2.type==CAND_MARIBOZU_LONG 
      && candle1.open>candle2.open) {
      return true;
   }
   return false;
}
bool isBreakawayBullish(CandleInfo &candle1, CandleInfo &candle2, CandleInfo &candle3, CandleInfo &candle4, CandleInfo &candle5){
  if(candle1.trend==DOWN 
      && !candle1.bull 
      && !candle2.bull 
      && !candle4.bull 
      && candle5.bull 
      && (candle1.type==CAND_LONG|| candle1.type==CAND_MARIBOZU_LONG) 
      && candle2.type==CAND_SHORT 
      && candle2.open<candle1.close 
      && candle3.type==CAND_SHORT && candle4.type==CAND_SHORT 
      && (candle5.type==CAND_LONG || candle5.type==CAND_MARIBOZU_LONG) 
      && candle5.close<candle1.close 
      && candle5.close>candle2.open){
      return true;
   }
   return false;
}

bool isBreakawayBearlish(CandleInfo &candle1, CandleInfo &candle2, CandleInfo &candle3, CandleInfo &candle4, CandleInfo &candle5){
   if((candle1.type==CAND_LONG || candle1.type==CAND_MARIBOZU_LONG)
      && candle2.type==CAND_SHORT 
      && candle2.open<candle1.close 
      && candle3.type==CAND_SHORT 
      && candle4.type==CAND_SHORT 
      && (candle5.type==CAND_LONG || candle5.type==CAND_MARIBOZU_LONG) 
      && candle5.close>candle1.close 
      && candle5.close<candle2.open) {
         return true;
      }
      return false;
}
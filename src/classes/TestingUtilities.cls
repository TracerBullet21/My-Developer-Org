public class TestingUtilities {

   static Integer idCounter = 1;
   @testVisible static String getFakeId(Schema.SObjectType sot)
   {
      String result = String.valueOf(idCounter);
      idCounter ++;
      return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
   }

}
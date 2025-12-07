public class LMS_FunnelAction {
    public String action;
    public String fieldApi;
    public String expected;
    
    /**
     * Parsuje definicję akcji lejka i zwraca obiekt LMS_FunnelAction.
     *
     * @return LMS_FunnelAction Zparsowany obiekt akcji lejka
     */
    
    public static LMS_FunnelAction parse(String definition) {
        List<String> parts = definition.split('\\.');
        
        LMS_FunnelAction fa = new LMS_FunnelAction();
        fa.action = parts.size() > 0 ? parts[0] : null;
        fa.fieldApi = parts.size() > 1 ? parts[1] : null;
        
        if (parts.size() > 2) {
            String tail = '';
            for (Integer i = 2; i < parts.size(); i++) {
                if (i > 2) tail += '.';
                tail += parts[i];
            }
            fa.expected = tail;
        } else {
            fa.expected = null;
        }
        
        return fa;
    }
}
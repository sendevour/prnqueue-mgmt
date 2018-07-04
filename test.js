const Prnqueue = require('./prnqueue-mgmt');//require the class
const prnqueue = new Prnqueue(); //create the object

//call the log method
//prnqueue.log('messgae');

//prnqueue.listPrintQueues();

//prnqueue.setDefaultPrintQueue('Xerox Global Print Driver PS');

//prnqueue.getDefaultPrintQueue();

//prnqueue.deletePrintQueue('printer1');

prnqueue.addTCPIPPort();
prnqueue.addPrintDriver('c:\\Windows\\Drivers\\Printers\\Xerox_GPD_PS\\x2UNIVP.inf', 'Xerox Global Print Driver PS', 1);

prnqueue.addPrintQueue('test123','10.20.25.35','Xerox Global Print Driver PS');

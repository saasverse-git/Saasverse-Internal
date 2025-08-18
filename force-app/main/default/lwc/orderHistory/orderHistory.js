import { LightningElement, wire, track } from 'lwc';
import getUserOrders from '@salesforce/apex/OrderHistoryController.getUserOrders';

export default class orderHistory extends LightningElement {
    @track orders = [];
    @track filteredOrders = [];
    @track startDate;
    @track EndDate;
    @track sortOrders = 'desc'

    @track columns = [
        { label: 'Order Number', fieldName: 'OrderNumber' },
        { label: 'Order Date', fieldName: 'EffectiveDate' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Total', fieldName: 'TotalAmount' }
    ];

    get sortoptions() {
        return [
            { label: 'Most Recent', value: 'desc' },
            { label: 'Oldest First', value: 'asc' }
        ]
    }

    @wire(getUserOrders)
    wiredOrders({ data, error }) {
        if (data) {
            this.orders = [...data];
            this.filterAndSort();
        } else if (error) {
            console.error('Error retrieving orders: ', error);
        }
    }

    handlestartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.EndDate = event.target.value;
    }

    handleSortChange(event) {
        console.log('event' + JSON.stringify(event.detail));
        this.sortOrders = event.detail.value;
        console.log('this.sortOrders !!!' + this.sortOrders);
        this.filterAndSort();

    }

    applyFilters() {
        this.filterAndSort();
    }

    clearFilters() {

        this.startDate = null;
        this.EndDate = null;
    }

    filterAndSort() {
        console.log('reached !!!');
        let temp = [...this.orders];
        console.log('temp !!!' + temp);
        console.log('this.startDate !!!' + this.startDate);
        if (this.startDate) {
            temp = temp.filter(order => new Date(order.EffectiveDate) >= new Date(this.startDate));
        }
        console.log('temp !!!' + temp);
        console.log('this.endDate !!!' + this.endDate);
        if (this.EndDate) {
            temp = temp.filter(order => new Date(order.EffectiveDate) <= new Date(this.EndDate));
        }
        console.log('temp !!!' + temp);

        temp.sort((a, b) => {
            return this.sortOrders === 'desc'
                ? new Date(b.EffectiveDate) - new Date(a.EffectiveDate)
                : new Date(a.EffectiveDate) - new Date(b.EffectiveDate);
        });
        console.log('temp !!!' + temp);

        this.filteredOrders = temp;
    }

}
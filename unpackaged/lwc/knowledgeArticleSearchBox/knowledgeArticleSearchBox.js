import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getKnowledgeRecords from '@salesforce/apex/Knowledge.getKnowledgeRecords';
import getGlobalKnowledgeRecords from '@salesforce/apex/Knowledge.getGlobalKnowledgeRecords';
import displayKnowledge from '@salesforce/apex/Knowledge.displayKnowledge';
import getVoteCount from '@salesforce/apex/Knowledge.getVoteCount';
import voteForknoledgeArticle from '@salesforce/apex/Knowledge.voteForknoledgeArticle';
import USER_ID from '@salesforce/user/Id';

export default class KnowledgeArticleSearchBox extends LightningElement {
    @api recordId;
    @track records = [];
    @track activeSections = [];
    @track searchTerm = '';
    @track tempSearchTerm = '';
    allowMultiple = true;
    knowledgeData = [];
    knowledgeBaseData;
    error;
    filteredRecords = [];
    searchCalled = false;
    description;
    status;
    isAssigned = false;
    userId = USER_ID;
    isCaseRecordPage = false;
    LikeCount = 0;
    DislikeCount = 0;
    openSectionRecordId;
    alreadyLikedByUser = false;
    alreadyDislikedByUser = false;
    runOnce = false;
    tempActiveSection = [];
    @track globalSearch = false;
    isLoading = false;

    get countOfRecords(){
        if(this.knowledgeData){
            return this.knowledgeData.length;
        }
        return 0;
    }

    get noResult(){
        if(this.globalSearch){
            return this.knowledgeData.length === 0;
        } else {
            if(this.searchCalled){
                return this.filteredRecords.length === 0;
            }
            return false;
        }
    }

    get likeCountValue() {
        return this.LikeCount;
    }

    get dislikeCountValue() {
        return this.DislikeCount;
    }

    get likeClass() {
        return this.alreadyLikedByUser ? 'icon liked' : 'icon';
    }

    get dislikeClass() {
        return this.alreadyDislikedByUser ? 'icon disliked' : 'icon';
    }

    get activeSectionsValue() {
        return this.activeSections;
    }




    @wire(getKnowledgeRecords, { recordId: '$recordId' })
    wiredKnowledge({ error, data }) {
        if (data) {
            if(!this.globalSearch){
                this.knowledgeBaseData = data.knowledgeRecords;
                this.knowledgeData = data.knowledgeRecords;
                this.description = data.description;
                if(data.reasonForContact != null || data.reasonForContact != undefined){
                    this.filterRecords(data.reasonForContact);
                    if(this.description != undefined || this.description != null){
                        this.searchGenericKeywords(data.description);
                    }
                    if(this.filteredRecords.length != 0){
                        this.knowledgeBaseData = this.filteredRecords;
                        this.knowledgeData = this.filteredRecords;
                        this.activeSections = [];
                    }
                }
                this.checkIfOnCaseRecordPage();
                this.error = undefined;
                console.log('Inside knowledge wire method!');
            }
        } else if (error) {
            this.error = error;
            console.log('knowledge wire error', error);
            this.knowledgeData = undefined;
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            const { attributes } = currentPageReference;
            if (
                attributes &&
                attributes.recordId &&
                attributes.objectApiName === 'Case'
            ) {
                if (this.recordId !== attributes.recordId) {
                    this.recordId = attributes.recordId;
                    console.log('Detected Case Record ID:', this.recordId);
                    this.isCaseRecordPage = true;
                }
            } else {
                this.isCaseRecordPage = false;
            }
        }
    }



    connectedCallback() {
        console.log('recordId', this.recordId);
    }
    handleToggle(event) {
        event.stopPropagation();
        const clickedSections = event.detail.openSections;
        if(!this.runOnce){
            this.runOnce = true;
            if (Array.isArray(this.activeSections) && this.activeSections.length > 0) {
                const newlyClicked = clickedSections.filter(section => !this.activeSections.includes(section));
                if(newlyClicked == null || newlyClicked == undefined){
                    this.activeSections = [];
                } else {
                    this.activeSections = newlyClicked;
                }
            } else {
                this.activeSections = clickedSections;
            }
        }
    }

    handleGlobalToggle(event) {
        this.globalSearch = event.target.checked;
        this.tempSearchTerm = '';
        if(this.globalSearch){
            this.knowledgeData = [];
        } else {
            this.knowledgeData = [...this.knowledgeBaseData];
            this.handleSearchClick();
        }
    }

    handleSearchInput(event) {
        this.tempSearchTerm = event.target.value;
        if(this.tempSearchTerm.length == 0){
            this.handleSearchClick();
        }
    }

    handleSearchClick() {
        this.isLoading = true;
        this.searchTerm = this.tempSearchTerm;
        if(this.globalSearch){
            if(this.searchTerm){
                getGlobalKnowledgeRecords({ searchKeyword: this.searchTerm})
                .then(result => {
                    this.knowledgeData = result;
                    this.searchCalled = true;
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Error checking assignment status:', error);
                    this.isLoading = false;
                });
            }
            this.searchCalled = false;
        } else {
            if(!this.searchTerm){
                this.knowledgeData = [...this.knowledgeBaseData];
                this.searchCalled = false;
                this.isLoading = false;
                return;
            }
            this.filterRecords(this.searchTerm);
            this.searchCalled = true;
            this.isLoading = false;
        }
    }

    filterRecords(filteringTerm){
        const term = filteringTerm.toLowerCase();
        this.filteredRecords = this.knowledgeData.filter(record =>
            record.Question__c?.toLowerCase().includes(term.toLowerCase()) ||
            record.Answer__c?.toLowerCase().includes(term.toLowerCase())
        );
        this.knowledgeData = this.filteredRecords.length > 0 ? this.filteredRecords : [...this.knowledgeBaseData];
        this.activeSections = [];
    }

    checkAssignment() {
        if (!this.recordId && !this.userId) return;

        displayKnowledge({ caseId: this.recordId, userId: this.userId })
            .then(result => {
                this.isAssigned = result;
                if(this.isAssigned && this.isCaseRecordPage){
                    this.dispatchEvent(new CustomEvent('openutility', { bubbles: true, composed: true }));
                }
            })
            .catch(error => {
                console.error('Error checking assignment status:', error);
            });
    }

    checkIfOnCaseRecordPage() {
        setTimeout(() => {
            const url = window.location.href;
            console.log('url', url);
            console.log('record Id', this.recordId);
            const isCasePage = /\/lightning\/r\/Case\/[^/]+\/view(\?.*)?/.test(url);

            console.log('Is on Case record page:', isCasePage);
            const isCaseListView = /\/lightning\/o\/Case\/list(\?.*)?/.test(window.location.href);
            console.log('isCaseListView', isCaseListView);

            if (isCasePage || isCaseListView) {
                console.log('BEFORE CHECK ASSIGNMENT');
                this.isCaseRecordPage = true;
                setTimeout(() => {
                    this.checkAssignment();
                }, 1500);
            }
        }, 1000);
    }

    searchGenericKeywords(inputText) {
        const stopWords = new Set([
            "a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as",
            "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "can", "cannot",
            "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each",
            "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd",
            "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i",
            "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", "me",
            "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other",
            "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "she", "she'd", "she'll", "she's", "should",
            "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves",
            "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through",
            "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were",
            "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", "whom", "why",
            "why's", "will", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", "your", "yours",
            "yourself", "yourselves"
        ]);

        const keywords = inputText
            .toLowerCase()
            .split(/\W+/)
            .filter(word => word && !stopWords.has(word));

        if (keywords.length === 0) {
            this.activeSections = [];
            return;
        }

        const filteredCopy = this.knowledgeData.filter(record => {
            const question = record.Question__c?.toLowerCase() || "";
            const answer = record.Answer__c?.toLowerCase() || "";

            return keywords.some(keyword =>
                question.includes(keyword) || answer.includes(keyword)
            );
        });

        if (filteredCopy.length > 0) {
            this.filteredRecords = filteredCopy;
            this.knowledgeData = [...this.filteredRecords];
            this.activeSections = [];
        }
    }


    handleFeedback(event) {
        event.stopPropagation();
        const type = event.currentTarget.dataset.type;
        const parentId = event.currentTarget.dataset.articleid;
        const knowledgeId = event.currentTarget.dataset.id;
        if (this.currentVote == type) {
            this.currentVote = null;
            this.alreadyLikedByUser = false;
            this.alreadyDislikedByUser = false;
        } else {
            if(this.currentVote != type){
                this.currentVote = type;
                if(this.currentVote == '5'){
                    this.alreadyLikedByUser = true;
                    this.alreadyDislikedByUser = false;
                }else if(this.currentVote == '1'){
                    this.alreadyDislikedByUser = true;
                    this.alreadyLikedByUser = false;
                }
            }
        }
        voteForknoledgeArticle({ parentId: parentId, voteType: this.currentVote, userId: this.userId})
            .then(result => {
                console.log('vote For Knowledge result', result);
                console.log('knowlege Id', knowledgeId);
                const tempEvent = {currentTarget: {dataset: {id: knowledgeId}}};
                this.handleSectionClick(tempEvent);
                console.log('calling handleSection click');
            })
            .catch(error => {
                console.error('Error updating or deleting vote: ', error);
            });
    }

    handleSectionClick(event){
        //event.stopPropagation();
        const clickedId = event.currentTarget.dataset.id;
        this.runOnce = false;
        console.log('active section', JSON.stringify(this.activeSections));
        if(this.activeSections != null){
            const article = this.knowledgeData.find(item => item.Id === clickedId);
            const knowledgeArticleId = article ? article.KnowledgeArticleId : null;
            getVoteCount({ recordId: knowledgeArticleId})
                .then(result => {
                    let likeCount = 0;
                    let dislikeCount = 0;
                    this.alreadyLikedByUser = false;
                    this.alreadyDislikedByUser = false;
                    result.forEach(record => {
                        if (record.Type === "5"){
                            likeCount++;
                            if(record.CreatedById == this.userId){
                                this.alreadyLikedByUser = true;
                                this.alreadyDislikedByUser = false;
                            }
                        } else if (record.Type === "1"){
                            dislikeCount++;
                            if(record.CreatedById == this.userId){
                                this.alreadyDislikedByUser = true;
                                this.alreadyLikedByUser = false;
                            }
                        }
                    });
                    this.LikeCount = likeCount;
                    this.DislikeCount = dislikeCount;
                })
                .catch(error => {
                    console.error('Error checking vote: ', error);
                });
        }
    }
}
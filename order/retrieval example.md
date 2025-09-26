// 노션 API를 사용한 관계형 데이터베이스 앱 예제
// 필요한 라이브러리: @notionhq/client

const { Client } = require('@notionhq/client');

class NotionRelationalApp {
  constructor(authToken) {
    this.notion = new Client({
      auth: authToken,
    });
  }

  // 1. 특정 페이지의 관련 데이터베이스들을 찾기
  async getRelatedDatabases(pageId) {
    try {
      // 페이지의 블록들을 가져와서 데이터베이스 블록 찾기
      const blocks = await this.notion.blocks.children.list({
        block_id: pageId,
      });

      const databases = blocks.results.filter(
        block => block.type === 'child_database'
      );

      return databases;
    } catch (error) {
      console.error('관련 데이터베이스 조회 실패:', error);
      throw error;
    }
  }

  // 2. 데이터베이스의 모든 페이지들을 가져오기
  async getDatabasePages(databaseId) {
    try {
      const response = await this.notion.databases.query({
        database_id: databaseId,
        sorts: [
          {
            timestamp: 'created_time',
            direction: 'descending'
          }
        ]
      });

      // 페이지 정보 정리
      const pages = response.results.map(page => ({
        id: page.id,
        title: this.extractTitle(page.properties),
        properties: page.properties,
        created_time: page.created_time,
        last_edited_time: page.last_edited_time
      }));

      return pages;
    } catch (error) {
      console.error('데이터베이스 페이지 조회 실패:', error);
      throw error;
    }
  }

  // 3. 특정 페이지의 상세 내용 가져오기
  async getPageContent(pageId) {
    try {
      // 페이지 메타데이터
      const page = await this.notion.pages.retrieve({
        page_id: pageId
      });

      // 페이지 컨텐츠 (블록들)
      const blocks = await this.notion.blocks.children.list({
        block_id: pageId
      });

      return {
        metadata: {
          id: page.id,
          title: this.extractTitle(page.properties),
          properties: page.properties,
          created_time: page.created_time,
          last_edited_time: page.last_edited_time
        },
        content: blocks.results
      };
    } catch (error) {
      console.error('페이지 내용 조회 실패:', error);
      throw error;
    }
  }

  // 4. 관계형 프로퍼티에서 연결된 페이지들 가져오기
  async getRelatedPages(pageId, relationPropertyName) {
    try {
      const page = await this.notion.pages.retrieve({
        page_id: pageId
      });

      const relationProperty = page.properties[relationPropertyName];
      
      if (relationProperty && relationProperty.type === 'relation') {
        const relatedPageIds = relationProperty.relation.map(rel => rel.id);
        
        // 각 관련 페이지의 내용 가져오기
        const relatedPages = await Promise.all(
          relatedPageIds.map(id => this.getPageContent(id))
        );

        return relatedPages;
      }

      return [];
    } catch (error) {
      console.error('관련 페이지 조회 실패:', error);
      throw error;
    }
  }

  // 제목 추출 헬퍼 함수
  extractTitle(properties) {
    const titleProperty = Object.values(properties).find(
      prop => prop.type === 'title'
    );
    
    if (titleProperty && titleProperty.title.length > 0) {
      return titleProperty.title[0].plain_text;
    }
    
    return 'Untitled';
  }

  // 텍스트 블록 내용 추출
  extractTextFromBlocks(blocks) {
    return blocks
      .filter(block => block.type === 'paragraph' || block.type === 'heading_1' || block.type === 'heading_2')
      .map(block => {
        const textArray = block[block.type]?.rich_text || [];
        return textArray.map(text => text.plain_text).join('');
      })
      .filter(text => text.length > 0);
  }
}

// 사용 예제
async function main() {
  const app = new NotionRelationalApp('your-notion-integration-token');

  try {
    // 1. 특정 페이지의 관련 데이터베이스들 찾기
    const pageId = 'your-page-id';
    const databases = await app.getRelatedDatabases(pageId);
    console.log('관련 데이터베이스들:', databases);

    if (databases.length > 0) {
      const databaseId = databases[0].id;
      
      // 2. 데이터베이스의 페이지들 가져오기
      const pages = await app.getDatabasePages(databaseId);
      console.log('데이터베이스 페이지들:', pages);

      if (pages.length > 0) {
        // 3. 첫 번째 페이지의 상세 내용 가져오기
        const pageContent = await app.getPageContent(pages[0].id);
        console.log('페이지 내용:', pageContent);

        // 4. 관련 페이지들 가져오기 (만약 관계형 프로퍼티가 있다면)
        const relatedPages = await app.getRelatedPages(pages[0].id, '관련_페이지');
        console.log('관련 페이지들:', relatedPages);
      }
    }

  } catch (error) {
    console.error('실행 오류:', error);
  }
}

// React 컴포넌트 예제 (프론트엔드용)
const NotionDatabaseViewer = ({ pageId, authToken }) => {
  const [databases, setDatabases] = useState([]);
  const [selectedDatabase, setSelectedDatabase] = useState(null);
  const [databasePages, setDatabasePages] = useState([]);
  const [selectedPage, setSelectedPage] = useState(null);
  const [pageContent, setPageContent] = useState(null);
  
  const app = new NotionRelationalApp(authToken);

  useEffect(() => {
    loadDatabases();
  }, [pageId]);

  const loadDatabases = async () => {
    try {
      const dbs = await app.getRelatedDatabases(pageId);
      setDatabases(dbs);
    } catch (error) {
      console.error('데이터베이스 로딩 실패:', error);
    }
  };

  const handleDatabaseSelect = async (databaseId) => {
    try {
      setSelectedDatabase(databaseId);
      const pages = await app.getDatabasePages(databaseId);
      setDatabasePages(pages);
      setSelectedPage(null);
      setPageContent(null);
    } catch (error) {
      console.error('데이터베이스 페이지 로딩 실패:', error);
    }
  };

  const handlePageSelect = async (pageId) => {
    try {
      setSelectedPage(pageId);
      const content = await app.getPageContent(pageId);
      setPageContent(content);
    } catch (error) {
      console.error('페이지 내용 로딩 실패:', error);
    }
  };

  return (
    <div className="notion-app">
      <div className="sidebar">
        <h3>데이터베이스 목록</h3>
        {databases.map(db => (
          <div 
            key={db.id}
            className="database-item"
            onClick={() => handleDatabaseSelect(db.id)}
          >
            {db.child_database?.title || 'Untitled Database'}
          </div>
        ))}
      </div>

      {selectedDatabase && (
        <div className="database-content">
          <h3>페이지 목록</h3>
          {databasePages.map(page => (
            <div 
              key={page.id}
              className="page-item"
              onClick={() => handlePageSelect(page.id)}
            >
              <h4>{page.title}</h4>
              <p>생성일: {new Date(page.created_time).toLocaleDateString()}</p>
            </div>
          ))}
        </div>
      )}

      {pageContent && (
        <div className="page-content">
          <h2>{pageContent.metadata.title}</h2>
          <div className="content-blocks">
            {app.extractTextFromBlocks(pageContent.content).map((text, index) => (
              <p key={index}>{text}</p>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

module.exports = { NotionRelationalApp, NotionDatabaseViewer };
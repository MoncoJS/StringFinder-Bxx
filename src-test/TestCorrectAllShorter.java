import static org.junit.Assert.*;

import org.junit.Test;

public class TestCorrectAllShorter {

	@Test
	public void test() {
		StringFinder a = new StringFinder(new Secret("ABCDEFG"));
		
		// correct string
		assertEquals(2,a.getGoal().evaluate("ABCDE"));
	}

}
